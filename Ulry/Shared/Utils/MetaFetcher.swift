//
//  MetaFetcher.swift
//  Urly
//
//  Created by Mattia Righetti on 12/23/21.
//

import Combine
import SwiftUI
import Foundation
import SwiftSoup

public enum MetaRodError: Error {
    case parseError(String)
    case unknown(String)
}

public class MetaRod: NSObject {
    
    public static var shared = MetaRod()
    
    fileprivate var document:Document? = nil
    
    public func build(_ urlstr:String) -> Self{
        do {
            guard let url = URL(string: urlstr), let html = try? String(contentsOf: url, encoding: .utf8) else { return self }
            self.document = try SwiftSoup.parse(html)
        } catch Exception.Error(let type, let message) {
            print("error type \(type) message \(message)")
        } catch {
            print("unknown error")
        }
        return self
    }
    
    public func getTitle() throws -> String? {
        do {
            let header = self.document?.head()
            let title = try header?.getElementsByTag("title")
            return try title?.text()
        } catch {
            throw MetaRodError.unknown("property")
        }
    }
    
    public func meta() throws -> [String : String]  {
           var meta:[String:String] = [:]
           do {
               let header = self.document?.head()
               let metaList = try header?.getElementsByTag("meta")
               try metaList?.forEach{ elm in
                   let prop = try elm.attr("property")
                   if (!prop.isEmpty) {
                       meta[prop] = try elm.attr("content")
                   }
               }
           } catch Exception.Error(_, let message) {
               throw MetaRodError.parseError(message)
           } catch {
               throw MetaRodError.unknown("failed")
           }
           return meta
    }
    
    public func og() throws -> [String : String]  {
        var og:[String:String] = [:]
        do {
            let header = self.document?.head()
            let metaList = try header?.getElementsByTag("meta")
            try metaList?.forEach{ elm in
                let prop = try elm.attr("property")
                if (!prop.isEmpty && prop.contains("og:")) {
                    og[prop] = try elm.attr("content")
                }
            }
            
            if og["og:title"] == nil {
                og["og:title"] = try getTitle()
            }
        } catch Exception.Error(_, let message) {
            throw MetaRodError.parseError(message)
        } catch {
            throw MetaRodError.unknown("failed")
        }
        
        return og
    }
}
