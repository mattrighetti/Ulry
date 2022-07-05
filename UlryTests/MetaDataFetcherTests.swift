//
//  MetaDataFetcherTests.swift
//  UlryTests
//
//  Created by Mattia Righetti on 7/3/22.
//

import LinkPresentation
import UIKit
import XCTest

class MetaDataFetcherTests: XCTestCase {
    func testMetaDataDownload() {
        let url = URL(string: "https://mattrighetti.com")!
        let e = expectation(description: "Wait for metadata")

        let lp = LPMetadataProvider()
        lp.startFetchingMetadata(for: url) { metadata, error in
            XCTAssertNil(error)
            XCTAssertNotNil(metadata)
            
            XCTAssertEqual(metadata!.title, "mattrighetti")
            XCTAssertEqual(metadata!.originalURL!.absoluteString, "https://mattrighetti.com")
            XCTAssertEqual(metadata!.url!.absoluteString, "https://mattrighetti.com/")
            
            e.fulfill()
        }
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
            lp.cancel()
        }
    }
    
    func testLpMetadataDataComplete() {
        let url = URL(string: "https://www.swiftbysundell.com")!
        let e = expectation(description: "Wait for metadata")
        
        let lp = LPMetadataProvider()
        lp.shouldFetchSubresources = true
        lp.startFetchingMetadata(for: url) { metadata, error in
            XCTAssertNil(error)
            XCTAssertNotNil(metadata)
            
            XCTAssertEqual(metadata!.title, "Swift by Sundell")
            XCTAssertEqual(metadata!.value(forKey: "summary") as! String, "Weekly Swift articles, podcasts and tips by John Sundell")
            XCTAssertNotNil(metadata!.imageProvider)
            XCTAssertEqual(metadata!.originalURL!.absoluteString, "https://www.swiftbysundell.com")
            XCTAssertEqual(metadata!.url!.absoluteString, "https://www.swiftbysundell.com/")
            
            guard let imageProvider = metadata!.imageProvider else {
                XCTFail("Image provider is not present")
                return
            }
            
            imageProvider.loadObject(ofClass: UIImage.self) { image, error in
                XCTAssertNil(error)
                XCTAssertNotNil(image)
                e.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
            lp.cancel()
        }
    }
}
