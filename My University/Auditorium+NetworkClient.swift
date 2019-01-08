//
//  Auditorium+NetworkClient.swift
//  My University
//
//  Created by Yura Voevodin on 12/19/18.
//  Copyright © 2018 Yura Voevodin. All rights reserved.
//

import Foundation

extension Auditorium {
    
    class NetworkClient {
        
        // MARK: - Properties
        
        let cacheFile: URL
        var completionHandler: ((_ error: Error?) -> ())?
        
        // MARK: - Initialization
        
        init(cacheFile: URL) {
            self.cacheFile = cacheFile
        }
        
        // MARK: - Download Auditoriums
        
        func downloadAuditoriums(_ completion: @escaping ((_ error: Error?) -> ())) {
            completionHandler = completion
            
            guard let url = URL(string: "http://localhost:3000/universities/sumdu/auditoriums.json") else {
                completionHandler?(nil)
                return
            }
            
            let task = URLSession.shared.downloadTask(with: url) { (url, response, error) in
                
                if let error = error {
                    self.completionHandler?(error)
                } else {
                    self.downloadFinished(url: url, response: response)
                }
            }
            task.resume()
        }
        
        private func downloadFinished(url: URL?, response: URLResponse?) {
            if let localURL = url {
                do {
                    /*
                     If we already have a file at this location, just delete it.
                     Also, swallow the error, because we don't really care about it.
                     */
                    try FileManager.default.removeItem(at: cacheFile)
                }
                catch { }
                
                do {
                    try FileManager.default.moveItem(at: localURL, to: cacheFile)
                    completionHandler?(nil)
                } catch {
                    completionHandler?(error)
                }
            } else {
                completionHandler?(nil)
            }
        }
    }
}
