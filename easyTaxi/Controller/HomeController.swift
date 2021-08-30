//
//  HomeController.swift
//  easyTaxi
//
//  Created by 黃梓峻 on 2021/8/10.
//

import UIKit
import Firebase
import MapKit

private let reusdIdentifier = "LocationCell"
private let annotationIdentifier = "DriverAnno"

private enum ActionButtonConfiguration {
    case showMenu
    case dismissActionView
    
    init() {
        self = .showMenu
    }
}

class HomeController: UIViewController {
    
    //MARK: - Properties
    
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    private let inputActivationView = LoactionInputActivationView()
    private let rideActionView = RideActionView()
    private let loactionInputView = LoactionInputView()
    private let tableView = UITableView()
    private var searchResult = [MKPlacemark]()
    private final let locationInputViewHeight = CGFloat(200)
    private final let rideActionViewHeight = CGFloat(300)
    private var actionButtonConfig = ActionButtonConfiguration()
    private var route: MKRoute?
    
    
    private var user: User? {
        didSet { loactionInputView.user = user!}
    }
    
    private let actionButton:UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        checkIfUserLoggedIn()
        enableLocationServices()
    }
    
    // MARK: - Selectors
    @objc func actionButtonPressed() {
        switch actionButtonConfig {
        case .showMenu:
            break
        case .dismissActionView:
           removeAnnotationsAndOverlays()
            
            mapView.showAnnotations(mapView.annotations, animated: true)
            
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.animateRideRideActionView(shouldShow: false)
            }
            break
        default:
            break
        }
    }
    
    //MARK: - API
    func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        Service.shared.fetchUserData(uid: currentUid) { user in
            self.user = user
        }
    }
    
    func fetchDrivers() {
        //如果有座標的話
        guard let location = locationManager?.location else {return}
        Service.shared.fetchDrivers(location: location) { driver in
            guard let coordinate = driver.location?.coordinate else {return}
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            //計算是否需要新的座標點 false的話需要加入新的座標點
            var driverIsVisible:Bool {
                return self.mapView.annotations.contains { annotations in
                    guard let driverAnno = annotations as? DriverAnnotation else {return false}
                    if driverAnno.uid == driver.uid {
                        driverAnno.updateAnnotationPosition(withCoordinate: coordinate)
                        return true
                    }
                    return false
                }
            }
            //是否加入標籤
            if !driverIsVisible {
                self.mapView.addAnnotation(annotation)
            }     
        }
    }
    
    func checkIfUserLoggedIn() {
        if Auth.auth().currentUser?.uid == nil  {
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .overFullScreen
                self.present(nav, animated: true, completion: nil)
            }
        }else {
            configure()
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .overFullScreen
                self.present(nav, animated: true, completion: nil)
            }
        }catch {
            print("DEBUG: Error sigining out")
        }
    }
    func configureNavigationBar() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
    }
    //MARK: - Helper Funtions
    
    private func configureActionButton(config: ActionButtonConfiguration) {
        switch config {
        case .showMenu:
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
            break
        case .dismissActionView:
 
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
            actionButtonConfig = .dismissActionView
            break
        default:
            break
        }
    }
    
    func configure() {
        configureUI()
        fetchUserData()
        fetchDrivers()
    }
    
    func configureUI() {
        configureMapView()
        configureRideActionView()
        
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor,left: view.leftAnchor,paddingTop: 16,paddingLeft: 20,width: 30 ,height: 30)
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimenSions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top:actionButton.bottomAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        //動畫呈現
        UIView.animate(withDuration: 2) {
            self.inputActivationView.alpha = 1
        }
        configureTableView()
    }
    
    func configureMapView() {
        view.addSubview(mapView)
        mapView.frame = view.frame
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
    }
    
    func configureLoactionInputView() {
        
        view.addSubview(loactionInputView)
        loactionInputView.anchor(top: view.topAnchor,left: view.leftAnchor, right: view.rightAnchor,height: locationInputViewHeight)
        loactionInputView.alpha = 0
        loactionInputView.delegate = self
        
        UIView.animate(withDuration: 0.45) {
            self.loactionInputView.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.locationInputViewHeight
            }
        }
    }
    
    func configureRideActionView() {
        view.addSubview(rideActionView)
        rideActionView.frame = CGRect(x: 0, y: view.frame.height , width:            view.frame.width, height: rideActionViewHeight)
    }
    
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.tableFooterView = UIView()
        tableView.register(LocationCell.self, forCellReuseIdentifier: reusdIdentifier)
        tableView.rowHeight = 60
        let height = view.frame.height - locationInputViewHeight
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        
        view.addSubview(tableView)
    }
    
    func dismissLocationView(completion:((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.3,animations: {
            self.loactionInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.loactionInputView.removeFromSuperview()
        }, completion: completion)
        
    }
    
    func animateRideRideActionView(shouldShow:Bool, destination: MKPlacemark? = nil) {
        let yOrigin = shouldShow ? self.view.frame.height - self.rideActionViewHeight :
            self.view.frame.height
        
        if shouldShow {
            guard let destination = destination else { return }
            rideActionView.destination = destination
        }
        
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = yOrigin
        }

    }
}


// MARK: - Map Helper Functions
private extension HomeController {
    func searchBy(naturalLanguageQuery:String, completion: @escaping([MKPlacemark]) -> Void) {
        var result = [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            
            response.mapItems.forEach { item in
                result.append(item.placemark)
                
            }
            completion(result)
        }
    }
    
    func generatePolyline(toDestination destination: MKMapItem) {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { response, error in
            guard let response = response else { return }
            self.route = response.routes[0]
            guard let polyline = self.route?.polyline else { return }
            self.mapView.addOverlay(polyline)
        }
    }
    
    func removeAnnotationsAndOverlays() {
        mapView.annotations.forEach { annotation in
            if let anno = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            }
        }
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
}

// MARK: - MKMapViewDelegate
extension HomeController: MKMapViewDelegate {
    //自定義標籤
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(overlay: polyline)
            lineRenderer.strokeColor = .mainBlueTint
            lineRenderer.lineWidth = 4
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
}

// MARK: - LocationServices
extension HomeController {
    
    func enableLocationServices() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            print("DEBUG: 無法使用狀態未確定")
            //詢問使用者一次是否可以被定位
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("DEBUG: Auth always..")
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("DEBUG: 使用者允許")
            //取得是否可以被總是定位
            locationManager?.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
}

extension HomeController:LoactionInputActivationViewDelegate {
    func presentLoactionInput() {
        inputActivationView.alpha = 0
        configureLoactionInputView()
        
    }
}

// MARK: -LoactionInputViewDelegate
extension HomeController:LoactionInputViewDelegate {
    func executeSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { results in
            self.searchResult = results
            self.tableView.reloadData()
        }
    }
    
    func dismissLoactionInputView() {
        dismissLocationView { _ in
            UIView.animate(withDuration: 0.5,animations: {
                self.inputActivationView.alpha = 1
            })
        }
    }
}

// MARK: - UITableViewDelegate/UITableViewDataSource

extension HomeController:UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Test"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : searchResult.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reusdIdentifier) as! LocationCell
        
        if indexPath.section == 1 {
            cell.placemark = searchResult[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlacemark = searchResult[indexPath.row]
        
        configureActionButton(config: .dismissActionView)
        
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestination: destination)
        
        dismissLocationView { _ in
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedPlacemark.coordinate
            self.mapView.addAnnotation(annotation)
            self.mapView.selectAnnotation(annotation, animated: true)
            
            let annotations = self.mapView.annotations.filter(
                { !$0.isKind(of: DriverAnnotation.self)})
            
            self.mapView.zoomToFit(annotations: annotations)
            
            self.animateRideRideActionView(shouldShow: true, destination: selectedPlacemark)
        }
    }
}
