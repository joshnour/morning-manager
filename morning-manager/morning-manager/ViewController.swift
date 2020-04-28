//
//  ViewController.swift
//  morning-manager
//
//  Created by Josh Nouriyelian on 4/17/20.
//  Copyright © 2020 Joshua Nouriyelian. All rights reserved.
//

import UIKit
import EventKit

struct WeatherMap: Codable {
    let list: [List]
}

struct List: Codable {
    let main: Main
    let weather: [Weather]
}

struct Weather: Codable {
    let icon: String
}

struct Main: Codable {
    let temp,feelsLike: Double
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
    }
}

class ViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    let defaults = UserDefaults.standard
    
    //A variable to allow us to customize the message at top based on the user's iPhone name
    @IBOutlet var welcome: UILabel!
    //A variable that allows us to display the weather at a given city
    @IBOutlet weak var location: UITextField!
    //A variable that allows us to display multiple calendar events
    @IBOutlet weak var table: UITableView!
    
    
    @IBOutlet var picture1: UIImageView!
    @IBOutlet var picture2: UIImageView!
    @IBOutlet var picture3: UIImageView!
    
    @IBOutlet var temperature1: UILabel!
    @IBOutlet var temperature2: UILabel!
    @IBOutlet var temperature3: UILabel!
    
    
    //Weather information every 3 hours (should use this and get a few data points)
    //http://api.openweathermap.org/data/2.5/forecast?q=Philadelphia&appid=731a78701392011b608d3dc2258b117f
    
    var weathers = [List]()
    var events = [EKEvent]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        location.delegate = self
        table.delegate = self
        table.dataSource = self
        //print(UIDevice.current.name)
        if let saved = defaults.string(forKey: "Location") {
            location.text = saved
        }
        fetchWeather()
        welcome.text = "Good morning \(UIDevice.current.name)!"
        fetchEvent()
    }
    
    private func fetchEvent() {
        let eventStore = EKEventStore()
        //Get calendar authorization
        if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
            eventStore.requestAccess(to: .event, completion: {
                granted, error in
            })
        } else {
        }
        let calendars = eventStore.calendars(for: .event)
        for calendar in calendars {
            let now = Date(timeIntervalSinceNow: 0)
            let twentyFourHours = Date(timeIntervalSinceNow: +24*3600)
            let predicate = eventStore.predicateForEvents(withStart: now, end: twentyFourHours, calendars: [calendar])
            let event = eventStore.events(matching: predicate)
            events.append(contentsOf: event)
        }
        let calendar = Calendar.current
        //Sort events by start time
        events.sort(by: {obj1,obj2 in
            calendar.component(.hour, from: obj1.startDate) < calendar.component(.hour, from: obj2.startDate)
        })
        self.table.reloadData()
    }
    
    private func fetchWeather() {
        //Insert your OpenWeatherMap API key below
        let key = ""
        let urlString = "https://api.openweathermap.org/data/2.5/forecast?q=\(location.text ?? "Philadelphia")&appid=\(key)"
        guard let url = URL(string: urlString) else { return }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data {
                if let decodedWeather = try? JSONDecoder().decode(WeatherMap.self, from: data) {
                    self.weathers = decodedWeather.list
                    DispatchQueue.main.async {
                        self.setWeather()
                    }
                }
            }
        }
        task.resume()
    }
    
    //This function sets the labels and images once we decode the weather
    private func setWeather() {
        let farenheight1 = convertToFarenheight(d: self.weathers[0].main.temp)

        temperature1.text = (String(format:"%.1f", farenheight1) + "℉")
        picture1.image = UIImage(named: self.weathers[0].weather[0].icon)
        
        let farenheight2 = convertToFarenheight(d: self.weathers[1].main.temp)
        temperature2.text = String(format:"%.1f", farenheight2) + "℉"
        picture2.image = UIImage(named: self.weathers[1].weather[0].icon)

        let farenheight3 = convertToFarenheight(d: self.weathers[2].main.temp)
        temperature3.text = String(format:"%.1f", farenheight3) + "℉"
        picture3.image = UIImage(named: self.weathers[2].weather[0].icon)
    }
    
    private func convertToFarenheight(d: Double) -> Double {
        return ((d - 273.15) * 9/5 + 32)
    }
    
    //TextField Methods
    func textFieldDidEndEditing(_ textField: UITextField) {
        fetchWeather()
        defaults.set(textField.text, forKey: "Location")
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    //TableView Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("")
        let thisEvent = events[indexPath.row]
        let calendar = Calendar.current
        //Start time has tag 10
        let cell = tableView.dequeueReusableCell(withIdentifier: "reusableCell")!
        if let startLabel = cell.viewWithTag(10) as? UILabel {
            let startHour = calendar.component(.hour, from: thisEvent.startDate)
            let startMinutes = calendar.component(.minute, from: thisEvent.startDate)
            let startMin = String(format: "%02d", startMinutes)
            startLabel.text = "\(startHour):\(startMin)"
        }
        //End time has tag 11
        if let endLabel = cell.viewWithTag(11) as? UILabel {
            let endHour = calendar.component(.hour, from: thisEvent.endDate)
            let endMinutes = calendar.component(.minute, from: thisEvent.endDate)
            let endMin = String(format: "%02d", endMinutes)
            endLabel.text = "\(endHour):\(endMin)"
        }
        //Event name has tag 7
        if let eventLabel = cell.viewWithTag(7) as? UILabel {
            eventLabel.text = "\(thisEvent.title ?? "No title")"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 69.0
    }
}

