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

class HomeController: UIViewController {
    
    //MARK: - Properties
    
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    private let inputActivationView = LoactionInputActivationView()
    private let loactionInputView = LoactionInputView()
    private let tableView = UITableView()
    private var searchResult = [MKPlacemark]()
    
    private final let locationInputViewHeight = CGFloat(200)
    
    private var user: User? {
        didSet { loactionInputView.user = user!}
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        checkIfUserLoggedIn()
        enableLocationServices()
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
    func configure() {
        configureUI()
        fetchUserData()
        fetchDrivers()
    }
    
    func configureUI() {
        configureMapView()
        
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimenSions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top:view.safeAreaLayoutGuide.topAnchor, paddingTop:  32)
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
        
        UIView.animate(withDuration: 0.3) {
            self.loactionInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
        } completion: { _ in
            self.loactionInputView.removeFromSuperview()
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
            }
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
}
