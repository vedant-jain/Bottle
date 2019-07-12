//
//  HomeCollectionViewController.swift
//  Bottle 2
//
//  Created by Vedant Jain on 06/04/19.
//  Copyright © 2019 Vedant Jain. All rights reserved.
//

import UIKit
import Alamofire

private let statsCellID = "statsCellID"
private let tasksPaneCellID = "tasksPaneCellID"

class HomeCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var tabViewControllerInstance: TabViewController?
    
    var tasksByMe: [Task] = []
    var tasksForMe: [Task] = []
    
    var workspaces: [Workspace] = []
    var users: [User] = []
    var projects: [Project] = []
    
    var mainUser: User?
    
//    let userDispatch: DispatchGroup = DispatchGroup()
    let dispatchGroup: DispatchGroup = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // to detect shake gesture
        self.becomeFirstResponder()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView!.register(StatsCollectionViewCell.self, forCellWithReuseIdentifier: statsCellID)
        collectionView.register(TasksPaneCollectionViewCell.self, forCellWithReuseIdentifier: tasksPaneCellID)
        
        collectionView.backgroundColor = .white
        
        // Register cell classes
        
        
        self.title = "User"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addTask))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(self.openWorkspaceView))

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if UserDefaults.standard.object(forKey: "userLogin") != nil {
            // already used
            let loggedIn = UserDefaults.standard.bool(forKey: "userLogin")
            if loggedIn == true {
                
                if UserDefaults.standard.object(forKey: "selectedWorkspace") == nil {
                    getWorkspaces(userId: self.tabViewControllerInstance?.userId ?? 6) { (workspacesArray) in
                        self.workspaces = workspacesArray
                        self.openWorkspaceView()
                    }
                }
                
                else {
                    reloadData()
                }
                
                self.title = UserDefaults.standard.string(forKey: "username") ?? "User"
                
            }
            else {
                presentLoginController()
            }
        }
        else {
            // app opened for the first time
            UserDefaults.standard.set(false, forKey: "userLogin")
            presentLoginController()
        }
    }
    
    func presentLoginController() {
        let loginViewController = LoginViewController()
        self.present(loginViewController, animated: true, completion: nil)
    }
    
    lazy var formLauncher: FormLauncher = {
        let launcher = FormLauncher()
        launcher.formView.homeCollectionViewControllerInstance = self
        return launcher
    }()
    
    @objc func addTask() {
        
        // take input (make a new view?)
        // add tasks to projects parameters: title, createdBy, workspace, details, assignedTo, project
        // send get request to get taskId (will have to loop through response and search with title
        // need to add tasks to projects separately
        self.formLauncher.setupViews {
            self.formLauncher.animate()
        }
    
    }
    
    @objc func openWorkspaceView() {
        let workspaceViewController = WorkspacesTableViewController()
        let workspaceNavigationController = UINavigationController(rootViewController: workspaceViewController)
        workspaceViewController.homeCollectionViewControllerInstance = self
        workspaceViewController.workspaces = self.workspaces
        self.present(workspaceNavigationController, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    // to detect shake gesture
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    // shake gesture
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            reloadData()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: statsCellID, for: indexPath) as! StatsCollectionViewCell
            cell.titleLabel.text = "Stats"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMMM dd"
            cell.subtitleLabel.text = dateFormatter.string(from: Date())
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tasksPaneCellID, for: indexPath) as! TasksPaneCollectionViewCell
            cell.userId = self.tabViewControllerInstance?.userId ?? 6
            cell.titleLabel.text = "Tasks"
            cell.users = self.users
            cell.tasksByMe = tasksByMe
            cell.tasksForMe = tasksForMe
            cell.mainUser = mainUser
            DispatchQueue.main.async {
                cell.collectionView.reloadData()
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item == 0 {
            //stats
            return CGSize(width: view.frame.width, height: 250)
        }
        else {
            // tasks pane
            return CGSize(width: view.frame.width, height: 500)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
    }
    
    fileprivate func reloadData() {
        networking(userId: self.tabViewControllerInstance?.userId ?? 6, workspaceId: tabViewControllerInstance?.workspace?.id ?? 1) {
            self.collectionView.reloadData()
        }
    }
    
    private func networking(userId: Int, workspaceId: Int, completion: @escaping () -> ()) {
        
        if let window = UIApplication.shared.keyWindow {
            LoadingOverlay.shared.showOverlay(view: window)
        }
        
        getTasksByMe(userId: userId) { (tasks) in
            self.tasksByMe = tasks
            self.dispatchGroup.leave()
        }
        
        getTasksForMe(userId: userId) { (tasks) in
            self.tasksForMe = tasks
            self.dispatchGroup.leave()
        }
        
        getWorkspaces(userId: userId) { (workspacesArray) in
            self.workspaces = workspacesArray
            self.dispatchGroup.leave()
        }
        
        getUsers(workspaceId: workspaceId) { () in
            self.tabViewControllerInstance?.users = self.users
            self.formLauncher.users = self.users
            self.dispatchGroup.leave()
        }
        
        getProjects(userId: userId) { (projects) in
            self.projects = projects
            self.dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            LoadingOverlay.shared.hideOverlayView()
            completion()
        }
        
    }
    
    private func getUsers(workspaceId: Int, completion: @escaping () -> ()) {
        
        // get list of users in workspace
        // use userIds to get details of each user
        
        dispatchGroup.enter()
        
        let url = "https://j8008zs2ol.execute-api.ap-south-1.amazonaws.com/default/workspaceusers"

        let parameters = [
            "workspaceId": workspaceId
        ]

        let headers = [
            "Content-type": "application/json"
        ]
        
        users = []
        
        Alamofire.request(url, method: .get, parameters: parameters, headers: headers).responseJSON { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let response = try JSONDecoder().decode([WorkspaceUser].self, from: data)
                        self.getUserDetails(users: response, completion: { (users) in
                            self.users = users
                            completion()
                        })
                    }
                    catch let error {
                        print("error", error)
                    }
                    
                }
                break
            case .failure(let error):
                print(error)
                break
            }
        }
        
    }
    
    private func getUserDetails(users: [WorkspaceUser], completion: @escaping ([User]) -> ()){
        
        var userDetailsArray: [User] = []
        
        if users.isEmpty == true {
            completion([User(id: -1, username: "@err", createdAt: "", updatedAt: "")])
        }
        
        for user in users {
        
            let userId = user.userId
            
            if userId == -1 {print("err")}
            
            let url = "https://qkvee3o84e.execute-api.ap-south-1.amazonaws.com/default/getusers"
            
            let headers = [
                "Content-type": "application/json"
            ]
            
            let parameters = [
                "id": userId
            ]
            
            var userDetails: User?
            
            Alamofire.request(url, method: .get, parameters: parameters as Parameters, headers: headers).responseJSON { (response) in
                switch response.result {
                case .success:
                    if let data = response.data {
                        do {
                            let response = try JSONDecoder().decode([User].self, from: data)
                            for user in response {
                                // only one element
                                userDetails = User(id: user.id, username: user.username, createdAt: user.createdAt, updatedAt: user.updatedAt)
                                userDetailsArray.append(userDetails!)
                                if userId! == self.tabViewControllerInstance?.userId! {
                                    self.mainUser = userDetails
                                }
                            }
                            if user.userId == users.last?.userId {completion(userDetailsArray)}
                        }
                        catch let error {
                            print("error", error)
                        }
                    }
                    break
                case .failure(let error):
                    print(error)
                    break
                }
            }
        }
    }
    
    private func getTasksForMe(userId: Int, completion: @escaping ([Task]) -> ()) {
        
        dispatchGroup.enter()
        
        var tasks: [Task] = []
        
        let url = "https://wa01k4ful5.execute-api.ap-south-1.amazonaws.com/default/tasks"
        
        // goes into tasksforme
        let parameters = [
            "assignedTo": userId
        ]
        
        let header = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: parameters, headers: header).responseJSON { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let response = try JSONDecoder().decode([Task].self, from: data)
                        if response.isEmpty == true {
                            completion(tasks)
                        }
                        for element in response {
                            tasks.append(element)
                            if element.id == response.last?.id {completion(tasks)}
                        }
                    }
                    catch let error {
                        print("error", error)
                    }
                }
                break
            case .failure(let error):
                print(error)
                break
            }
        }
        
    }
    
    private func getTasksByMe(userId: Int, completion: @escaping ([Task]) -> ()) {
        
        dispatchGroup.enter()
        
        var tasks: [Task] = []
        
        let url = "https://wa01k4ful5.execute-api.ap-south-1.amazonaws.com/default/tasks"
        
        // goes into tasksbyme
        let parameters = [
            "createdBy": userId
        ]
        
        let header = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: parameters, headers: header).responseJSON { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let response = try JSONDecoder().decode([Task].self, from: data)
                        if response.isEmpty == true {
                            completion(tasks)
                        }
                        for element in response {
                            tasks.append(element)
                            if element.id == response.last?.id {completion(tasks)}
                        }
                    }
                    catch let error {
                        print("error", error)
                    }
                }
                break
            case .failure(let error):
                print(error)
                break
            }
        }
        
    }
    
    private func getWorkspaces(userId: Int, completion: @escaping ([Workspace]) -> ()) {
        
        dispatchGroup.enter()
        
        workspaces = []
        
        let url = "https://j8008zs2ol.execute-api.ap-south-1.amazonaws.com/default/workspaceusers"
        
        let parameters = [
            "userId": userId
        ]
        
        let header = [
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: parameters, headers: header).responseJSON { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let response = try JSONDecoder().decode([WorkspaceUser].self, from: data)
                        self.getWorkspaceDetails(ids: response, completion: { (workspacesArray) in
                            completion(workspacesArray)
                        })
                        
                    }
                    catch let error {
                        print("error", error)
                    }
                }
                break
            case .failure(let error):
                print(error)
                break
            }
        }
        
    }
    
    fileprivate func getWorkspaceDetails(ids: [WorkspaceUser], completion: @escaping ([Workspace]) -> ()) {
        
        var workspaceDetailsArray: [Workspace] = []
        
        // if no workspace is available
        if ids.isEmpty == true {
            completion([Workspace(id: -1, name: "No workspaces found", createdBy: tabViewControllerInstance?.userId, createdAt: "", updatedAt: "")])
            return
        }
        
        for id in ids {
            
            let url = "https://7dq8nzhy1e.execute-api.ap-south-1.amazonaws.com/default/workspace"
            
            let parameters = [
                "id": id.workspaceId
            ]
            
            let headers = [
                "Content-type": "application/json"
            ]
            
            Alamofire.request(url, method: .get, parameters: parameters as Parameters, headers: headers).responseJSON { (response) in
                switch response.result {
                case .success:
                    if let data = response.data {
                        do {
                            let response = try JSONDecoder().decode([Workspace].self, from: data)
                            for element in response {
                                workspaceDetailsArray.append(element)
                            }
                            if id.workspaceId == ids.last?.workspaceId {completion(workspaceDetailsArray)}
                        }
                        catch let error {
                            print("error", error)
                        }
                    }
                    break
                case .failure(let error):
                    print(error)
                    break
                }
            }
            
        }
        
    }
    
    fileprivate func getProjects(userId: Int, completion: @escaping ([Project]) -> ()) {
        
        dispatchGroup.enter()
        
        var projectDetailsArray: [Project] = []
        
        let url = "https://wg9fx8sfq8.execute-api.ap-south-1.amazonaws.com/default/projects"
        
        let parameters = [
            "createdBy": userId
        ]
        
        let headers = [
            "Content-type": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: parameters, headers: headers).responseJSON { (response) in
            switch response.result {
            case .success:
                if let data = response.data {
                    do {
                        let response = try JSONDecoder().decode([Project].self, from: data)
                        if response.isEmpty == true {
                            completion([Project(id: -1, name: "No projects found", createdBy: self.tabViewControllerInstance?.userId, createdAt: "", updatedAt: "", workspace: self.tabViewControllerInstance?.workspace?.id)])
                            return
                        }
                        for element in response {
                            projectDetailsArray.append(element)
                            if element.id == response.last?.id {completion(projectDetailsArray)}
                        }
                    }
                    catch let error {
                        print("error", error)
                    }
                }
                break
            case .failure(let err):
                print(err)
                break
            }
        }
        
    }
    
}
