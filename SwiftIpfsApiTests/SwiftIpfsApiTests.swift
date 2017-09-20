//
//  SwiftIpfsApiTests.swift
//  SwiftIpfsApiTests
//
//  Created by Matteo Sartori on 20/10/15.
//  Copyright © 2015 Teo Sartori. All rights reserved.
//
//  Licensed under MIT See LICENCE file in the root of this project for details.

import XCTest
@testable import SwiftIpfsApi
import SwiftMultiaddr
import SwiftMultihash

class SwiftIpfsApiTests: XCTestCase {

//    var hostString      = "ipfs.infura.io" //"192.168.5.8"
    var hostString      = "127.0.0.1" //"192.168.5.8"
    let hostPort        = 5001
    
    /// Your own IPNS node hash
    let nodeIdString    = "QmWNwhBWa9sWPvbuS5XNaLp6Phh5vRN77BZRF5xPWG3FN1"
    
    /// Another know neighbouring hash
    let altNodeIdString = "QmSoLnSGccFuZQJzRadHn95W2CrSFmZuTdDWP8HXaHca9z"

    let peerIPAddr = "/ip4/104.236.176.52/tcp/4001"
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBoundary() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let soRandom = Multipart.createBoundary()
        print(soRandom.characters.count)
    }
    
    func testRefsLocal() {
        
        let refsLocal = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)

            try api.refs.local() {
                (localRefs: [Multihash]) in
                
                for mh in localRefs {
                    print(b58String(mh))
                }
                dispatchGroup.leave()
            }
        }
        
        tester(refsLocal)
    }
    
    func testPin() {
        
        let pinAdd = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let multihash = try fromB58String("Qmb4b83vuYMmMYqj5XaucmEuNAcwNBATvPL6CNuQosjr91")
            
            try api.pin.add(multihash) {
                (pinnedHashes: [Multihash]) in
                
                for mh in pinnedHashes {
                    print(b58String(mh))
                }
                
                dispatchGroup.leave()
            }
        }
        
        tester(pinAdd)
        
        
        let pinLs = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            
            try api.pin.ls() {
                (pinned: [Multihash : JsonType]) in
                
                for (k,v) in pinned {
                    print("\(b58String(k)) \((v.object?["Type"]?.string)!)")
                }
                dispatchGroup.leave()
            }
        }
        
        tester(pinLs)
        
        let pinRm = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let multihash = try fromB58String("Qmb4b83vuYMmMYqj5XaucmEuNAcwNBATvPL6CNuQosjr91")
            
            try api.pin.rm(multihash) {
                (removed: [Multihash]) in
                
                for hash in removed {
                    print("Removed hash:",b58String(hash))
                }
                dispatchGroup.leave()
            }
        }
        
        tester(pinRm)
    }
    
    func testRepo() {
        let repoGc = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            
            /** First we do an ls of something we know isn't pinned locally.
                This causes it to be copied to the local node so that the gc has
                something to collect. */
            let tmpGroup = DispatchGroup()
            
            tmpGroup.enter()

            let multihash = try fromB58String("QmTtqKeVpgQ73KbeoaaomvLoYMP7XKemhTgPNjasWjfh9b")
            try api.ls(multihash){ _ in tmpGroup.leave() }
            tmpGroup.wait(timeout: DispatchTime.distantFuture)
            
            
            try api.repo.gc() {
                result in
                if let removed = result.array {
                    for ref in removed {
                        print("removed: ",(ref.object?["Key"]?.string)!)
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        tester(repoGc)
    }
    
    func testBlock() {
        
        let blockPut = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let rawData: [UInt8] = Array("hej verden".utf8)
            
            try api.block.put(rawData) {
                (result: MerkleNode) in
                
                XCTAssert(b58String(result.hash!) == "QmR4MtZCAUkxzg8ewgNp6hDVgtqnyojDSWVF4AFG9RWsYw")
                print("ipfs.block.put test:")
//                for mt in result {
                    print("Name:", result.name)
                    print("Hash:", b58String(result.hash!))
//                }
                dispatchGroup.leave()
            }
        }
        
        tester(blockPut)
        
        
        let blockGet = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let multihash = try fromB58String("QmR4MtZCAUkxzg8ewgNp6hDVgtqnyojDSWVF4AFG9RWsYw")
            
            try api.block.get(multihash) {
                (result: [UInt8]) in
                    let res = String(bytes: result, encoding: String.Encoding.utf8)
                    XCTAssert(res == "hej verden")
                    dispatchGroup.leave()
            }
        }
        
        tester(blockGet)
        
        
        let blockStat = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let multihash = try fromB58String("QmR4MtZCAUkxzg8ewgNp6hDVgtqnyojDSWVF4AFG9RWsYw")
            
            try api.block.stat(multihash) {
                result in
                
                let hash = result.object?["Key"]?.string
                let size = result.object?["Size"]?.number

                if hash == nil || size == nil
                    || hash != "QmR4MtZCAUkxzg8ewgNp6hDVgtqnyojDSWVF4AFG9RWsYw"
                    || size != 10 {
                    XCTFail()
                }
                dispatchGroup.leave()
            }
        }
        
        tester(blockStat)
    }
    
    func testObject() {
        
        let objectNew = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.object.new() {
                (result: MerkleNode) in
                print(result.hash)
                /// A new ipfs object always has the same hash so we can assert against it.
                XCTAssert(b58String(result.hash!) == "QmdfTbBqBPQ7VNxZEYEj14VmRuZBkqFbiwReogJgS1zR1n")
                dispatchGroup.leave()
            }
        }
        
        tester(objectNew)
        
        let objectPut = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let data = [UInt8]("{ \"Data\" : \"Dauz\" }".utf8)
            
            try api.object.put(data) {
                (result: MerkleNode) in
                print(result.hash)
                
                XCTAssert(b58String(result.hash!) == "QmUqvXbE4s9oTQNhBXm2hFapLq1pnuuxsMdxP9haTzivN6")
                dispatchGroup.leave()
            }
        }
        
        tester(objectPut)
        
        let objectGet = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let multihash = try fromB58String("QmUqvXbE4s9oTQNhBXm2hFapLq1pnuuxsMdxP9haTzivN6")
            
            try api.object.get(multihash) {
                (result: MerkleNode) in
                
                XCTAssert(result.data! == Array("Dauz".utf8))
                dispatchGroup.leave()

            }
        }
        
        tester(objectGet)
        
        
        let objectLinks = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let multihash = try fromB58String("QmR3azp3CCGEFGZxcbZW7sbqRFuotSptcpMuN6nwThJ8x2")
            
            try api.object.links(multihash) {
                (result: MerkleNode) in
                
                print(b58String(result.hash!))
                /// There should be two links off the root:
                if let links = result.links, links.count == 2 {
                    let link1 = links[0]
                    let link2 = links[1]
                    XCTAssert(b58String(link1.hash!) == "QmWfzntFwgPf9T9brQ6P2PL1BMoH16jZvhanGYtZQfgyaD")
                    XCTAssert(b58String(link2.hash!) == "QmRJ8Gngb5PmvoYDNZLrY6KujKPa4HxtJEXNkb5ehKydg2")
                } else {
                    XCTFail()
                }
                dispatchGroup.leave()
                
            }
        }
        
        tester(objectLinks)
        
    }

    func testObjectPatch() {
        
        let setData = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            
            /// Get the empty directory object to start off with.
            try api.object.new() {
                (result: MerkleNode) in

                let data = "This is a longer message."
                try api.object.patch(result.hash!, cmd: .SetData, args: data) {
                    result in
                    
                    print(b58String(result.hash!))
                    dispatchGroup.leave()
                }
            }
        }
        
        tester(setData)

        let appendData = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            
            /// The previous hash that was returned from setData
            let previousMultihash = try fromB58String("QmQXys2Xv5xiNBR21F1NNwqWC5cgHDnndKX4c3yXwP4ywj")
            /// Get the empty directory object to start off with.
            
            let data = "Addition to the message."
            try api.object.patch(previousMultihash, cmd: .AppendData, args: data) {
                result in
                
                print(b58String(result.hash!))
                
                /// Now we request the data from the new Multihash to compare it.
                try api.object.data(result.hash!) {
                    result in
                    
                    let resultString = String(bytes: result, encoding: String.Encoding.utf8)
                    XCTAssert(resultString == "This is a longer message.Addition to the message.")
                    dispatchGroup.leave()
                }
            }
        }
        
        tester(appendData)

        
        let objectPatch = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)

            let hash = "QmUYttJXpMQYvQk5DcX2owRUuYJBJM6W7KQSUsycCCE2MZ" /// a file
            let hash2 = "QmVtU7ths96fMgZ8YSZAbKghyieq7AjxNdcqyVzxTt3qVe" /// a directory
            
            /// Get the empty directory object to start off with.
            try api.object.new(.UnixFsDir) {
                (result: MerkleNode) in

                /** This uses the directory object to create a new object patched
                    with the object of the given hash. */
                try api.object.patch(result.hash!, cmd: IpfsObject.ObjectPatchCommand.AddLink, args: "foo", hash) {
                    (result: MerkleNode) in
                    
                    /// Get a new object from the previous object patched with the object of hash2
                    try api.object.patch(result.hash!, cmd: IpfsObject.ObjectPatchCommand.AddLink, args: "ars", hash2) {
                        (result: MerkleNode) in
                        
                        /// get the new object's links to check against.
                        try api.object.links(result.hash!) {
                            (result: MerkleNode) in
                            
                            /// Check that the object's link is the same as 
                            /// what we originally passed to the patch command.
                            if let links = result.links, links.count == 2,
                                let linkHash = links[1].hash, b58String(linkHash) == hash {}
                            else { XCTFail() }
                            
                            /// Now try to remove it and check that we only have one link.
                            try api.object.patch(result.hash!, cmd: .RmLink, args: "foo") {
                                (result: MerkleNode) in
                                
                                /// get the new object's links to check against.
                                try api.object.links(result.hash!) {
                                    (result: MerkleNode) in

                                    if let links = result.links, links.count == 1,
                                        let linkHash = links[0].hash, b58String(linkHash) == hash2 {}
                                    else { XCTFail() }

                                    dispatchGroup.leave()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        tester(objectPatch)
    }
    
    
    func testName() {
    
        var idHash: String = ""
        /// Start test by storing the existing hash so we can restore it after testing.
        let nameResolvePublish = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.name.resolve(){
                result in
                
//                idHash = result.stringByReplacingOccurrencesOfString("/ipfs/", withString: "")
                idHash = result.replacingOccurrences(of: "/ipfs/", with: "")
                dispatchGroup.leave()
            }
        }
        
        tester(nameResolvePublish)
        
        let publishedPath = "/ipfs/" + idHash
        
        let publish = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let multihash = try fromB58String(idHash)
            try api.name.publish(hash: multihash) {
                result in
                
                XCTAssert(  (result.object?["Name"]?.string)! == self.nodeIdString &&
                            (result.object?["Value"]?.string)! == publishedPath)
                dispatchGroup.leave()
            }
        }
        
        self.tester(publish)
        
        let resolve = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.name.resolve(){
                result in
                XCTAssert(result == publishedPath)
                dispatchGroup.leave()
            }
        }
        
        self.tester(resolve)
    }
    
    func testDht() {
        
        do {
            /// Common
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let neighbour = self.altNodeIdString
            let multihash = try fromB58String("QmUFtMrBHqdjTtbebsL6YGebvjShh3Jud1insUv12fEVdA")
            
            let findProvs = { (dispatchGroup: DispatchGroup) throws -> Void in
                try api.dht.findProvs(multihash) {
                    result in
                    
                    var pass = false
                    repeat {
                        guard case .Array(let providers) = result else { break }
                        
                        for prov in providers {
                            
                            guard   case .Object(let obj) = prov,
                                    case .Array(let responses) = obj["Responses"]! else { continue }
                            
                            for response in responses {
                                
                                guard   case .Object(let ars) = response,
                                        case .String(let provHash) = ars["ID"]! else { continue }
                                
                                /// This node should definitely be in the dht.
                                if provHash == self.nodeIdString { pass = true }
                            }
                        }
                    } while false
                    
                    XCTAssert(pass)
                    
                    dispatchGroup.leave()
                }
            }
            
/// redo this test to account for the fact that it must be explicitly stopped
//tester(findProvs)
            
            
            let query = { (dispatchGroup: DispatchGroup) throws -> Void in
                /// This nearest works for me but may need changing to something local to the tester.
                let nearest = try fromB58String(neighbour)
                try api.dht.query(nearest) {
                    result in
                    /// assert against some known return value
                    print(result)
                    dispatchGroup.leave()
                }
            }
            
//            tester(query)
            
            
            let findPeer = { (dispatchGroup: DispatchGroup) throws -> Void in
                /// This peer works for me but may need changing to something local to the tester.
                let peer = try fromB58String(neighbour)
                
                /// At the moment the findpeer wraps the stream json in an array
                try api.dht.findpeer(peer) {
                    result in
                    
                    var pass = false
                    
                    if let resArray = result.object?["Responses"]?.array {
                        for res in resArray {
                            if res.object?["ID"]?.string == neighbour {
                                pass = true
                            }
                        }
                    }
                    XCTAssert(pass)
                    
                    dispatchGroup.leave()
                }
            }
            
            tester(findPeer)
            
//            let put = { (dispatchGroup: dispatch_group_t) throws -> Void in
//            }
//            tester(put)
//            let get = { (dispatchGroup: dispatch_group_t) throws -> Void in
//            }
//            tester(get)
            
        } catch {
            print("testDht error \(error)")
        }
    }
    
    /// If this fails check from the command line that the ipns path actually resolves
    /// to the checkHash before thinking this is actually broken. Ipns links do change.
    func testFileLs() {
                
        let lsIpns = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            /// basedir hash
            let path = "/ipns/QmaCpDMGvV2BGHeYERUEnRQAwe3N8SzbUtfsmvsqQLuvuJ"
            
            /// lvl2file hash
            let checkHash = "QmSiTko9JZyabH56y2fussEt1A5oDqsFXB3CkvAqraFryz"

            try api.file.ls(path) { result in
                XCTAssert(result.object?["Objects"]?.object?[checkHash]?.object?["Hash"]?.string == checkHash)
                dispatchGroup.leave()
            }
        }
            
        tester(lsIpns)
        
        let lsIpfs = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let checkHash = "QmQHAVCpAQxU21bK8VxeWisn19RRC4bLNFV4DiyXDDyLXM"
            let objHash = "QmQuQzFkULYToUBrMtyHg2tjvcd93N4kNHPCxfcFthB2kU"
            let path = "/ipfs/" + objHash
            
            try api.file.ls(path) {
                result in
                XCTAssert(result.object?["Objects"]?.object?[objHash]?.object?["Links"]?.array?[0].object?["Hash"]?.string == checkHash)
                dispatchGroup.leave()
            }
        }
            
        tester(lsIpfs)
        
    }
    /*
    func testBootstrap() {
        
        do {
            
            //let trustedPeer = "/ip4/104.131.131.82/tcp/4001/ipfs/QmaCpDMGvV2BGHeYERUEnRQAwe3N8SzbUtfsmvsqQLuvuJ"
            //let trustedPeer2 = "/ip4/104.236.176.52/tcp/4001/ipfs/QmSoLnSGccFuZQJzRadHn95W2CrSFmZuTdDWP8HXaHca9z"
            let trustedPeer = "/ip4/192.168.1.129/tcp/4001/ipfs/QmXCwfZdyL3TsJf2dZLxydan2rDCDx67vTGxPgzehxUCz4"
            let trustedPeer2 = "/ip4/10.129.41.121/tcp/4001/ipfs/QmXCwfZdyL3TsJf2dZLxydan2rDCDx67vTGxPgzehxUCz4"

            let tpMultiaddr = try newMultiaddr(trustedPeer)
            let tpMultiaddr2 = try newMultiaddr(trustedPeer2)
            
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
        
            let rm = { (dispatchGroup: DispatchGroup) throws -> Void in
                
                let tPeers = [tpMultiaddr, tpMultiaddr2]
                
                try api.bootstrap.rm(tPeers) {
                    (peers: [Multiaddr]) in
                    
                    for peer in peers {
                        print(try peer.string())
                    }

                    let a = try peers[0].string() == trustedPeer
                    let b = try peers[1].string() == trustedPeer2
                    XCTAssert(peers.count == 2 && a && b)
                    
                    dispatchGroup.leave()
                }
            }
            
            tester(rm)
            
            let bootstrap = { (dispatchGroup: DispatchGroup) throws -> Void in
                
                try api.bootstrap.list() {
                    (peers: [Multiaddr]) in
                    for peer in peers {
                       print(try peer.string())
                    }
                    dispatchGroup.leave()
                }
            }
            
            tester(bootstrap)
            
            let add = { (dispatchGroup: DispatchGroup) throws -> Void in
                
                let tPeers = [tpMultiaddr, tpMultiaddr2]
                
                try api.bootstrap.add(tPeers) {
                    (peers: [Multiaddr]) in
                    
                    for peer in peers {
                        print(try peer.string())
                    }

                    if peers.count == 2 {
                        let t1 = try peers[0].string() == trustedPeer
                        let t2 = try peers[1].string() == trustedPeer2
                        XCTAssert(t1 && t2)
                    } else { XCTFail() }
                    
                    dispatchGroup.leave()
                }
            }
            
            tester(add)
        
        } catch {
            print("Bootstrap test error: \(error)")
        }
    }
 */
    
    func testSwarmPeers() {
        
        /// NB: This test will require the user to change the knownPeer to a known peer.
        let knownPeer = peerIPAddr+"/ipfs/"+self.altNodeIdString
        
        let swarmPeers = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.swarm.peers(){
                (peers: [Multiaddr]) in
                
                var pass = false
                for peer in peers {
                    pass = (try peer.string() == knownPeer)
                    if pass { break }
                }
                XCTAssert(pass)
                dispatchGroup.leave()
            }
        }
        
        tester(swarmPeers)
    }
    
    func testSwarmAddrs() {
        let swarmAddrs = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.swarm.addrs(){
                addrs in

                XCTAssert(addrs.object?[self.altNodeIdString]?.array?[0].string == self.peerIPAddr)
                
                dispatchGroup.leave()
            }
        }
        
        tester(swarmAddrs)
    }

    func testSwarmConnect() {
        
        let swarmDisConnect = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            
            /// NB: This test will require the user to change the peerAddress to a known peer.
            let peerAddress = self.peerIPAddr+"/ipfs/"+self.altNodeIdString
            let expectedMessage = "connect \(self.altNodeIdString) success"
            
            try api.swarm.connect(peerAddress){
                result in
                
                XCTAssert(result.object?["Strings"]?.array?[0].string! == expectedMessage)
                
                try api.swarm.disconnect(peerAddress) {
                    result in
                    
                    XCTAssert(result.object?["Strings"]?.array?[0].string! == "dis" + expectedMessage)
                    dispatchGroup.leave()
                }
            }
        }
        
        tester(swarmDisConnect)
    }
    
    
    func testDiag() {
        
        let net = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.diag.net() {
                result in
                print(result)
                /// do comparison with truth here.
                dispatchGroup.leave()
            }
        }
        
        tester(net)
        
        let sys = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.diag.sys() {
                result in
                print(result)
                /// do comparison with truth here.
                dispatchGroup.leave()
            }
        }
        tester(sys)
    }
    
    func testConfig() {
        let show = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.config.show() {
                result in
                print(result)
                /// do comparison with truth here. Currently by visual inspection :/
                dispatchGroup.leave()
            }
        }
        
        tester(show)
        
        let set = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.config.set("Teo", value: "42") {
                result in
                
                try api.config.get("Teo") {
                    result in
                    /// do comparison with truth here.
                    if case .String(let strResult) = result, strResult == "42" { } else {
                        XCTFail()
                    }
                    dispatchGroup.leave()
                }
            }
        }
    
        tester(set)
        
   
        let get = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.config.get("Datastore.Type") {
                result in
                /// do comparison with truth here.
                if case .String(let strResult) = result, strResult == "leveldb" { } else {
                    XCTFail()
                }
                dispatchGroup.leave()
            }
        }
        
        tester(get)

    }
    
    
    func testBaseCommands() {
        
        /// For this test assert that the resulting links' name is Mel.html and MelKaye.png
        let lsTest = { (dispatchGroup: DispatchGroup) throws -> Void in

            let multihash = try fromB58String("QmPXME1oRtoT627YKaDPDQ3PwA8tdP9rWuAAweLzqSwAWT")
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.ls(multihash) {
                results in
                
                var pass = false
                let node = results[0]
                if let links = node.links ,
                        links.count == 5 &&
                        links[0].name! == "contact" &&
                        links[1].name! == "help" &&
                        links[2].name! == "quick-start" &&
                        links[3].name! == "readme" &&
                        links[4].name! == "security-notes" {
                    pass = true
                }
                
                XCTAssert(pass)
                
                /// do comparison with truth here.
                dispatchGroup.leave()
            }

        }
            
        tester(lsTest)
            
            
        let catTest = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let multihash = try fromB58String("QmYeQA5P2YuCKxZfSbjhiEGD3NAnwtdwLL6evFoVgX1ULQ")
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            
            try api.cat(multihash) {
                result in
                print("cat:",String(bytes: result, encoding: String.Encoding.utf8)!)
                dispatchGroup.leave()
            }
        }
        
        tester(catTest)
        
    }

    func testPing() {
        
        let ping = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.ping(self.altNodeIdString) {
               result in
                
                if let pings = result.array {
                    for ping in pings {
                        print(ping.object?["Text"] ?? "-")
                        print(ping.object?["Time"] ?? "-")
                        print(ping.object?["Success"] ?? "-")
                    }
                }

                dispatchGroup.leave()
            }
        }
        
        tester(ping)
    }
    
    func testIds() {
        
        do {
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let idString = self.nodeIdString
            
            let id = { (dispatchGroup: DispatchGroup) throws -> Void in
                try api.id(idString) {
                    result in
                    
                    XCTAssert(result.object?["ID"]?.string == idString)
                    dispatchGroup.leave()
                }
            }
            
            tester(id)
            
            let idDefault = { (dispatchGroup: DispatchGroup) throws -> Void in
                try api.id() {
                    result in
                    
                    XCTAssert(result.object?["ID"]?.string == idString)
                    dispatchGroup.leave()
                }
            }
            
            tester(idDefault)
            
        } catch {
            print("testIds error:\(error)")
        }
    }
    
    
    func testVersion() {
        let version = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.version() {
                version in
                print(version)
                dispatchGroup.leave()
            }
        }
        
        tester(version)
        
    }
    
    func testCommands() {
        let commands = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.commands(true) {
                result in
               
                if let commands = result.object {
                    for (k,v) in commands {
                        print("k: ",k)
                        print("v: ",v)
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        tester(commands)
        
    }
    
    func testStats() {
        let stats = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            try api.stats.bw() {
                result in
               
                /// We can't check for the values as they change constantly but at 
                /// least we can check for the keys being there.
                XCTAssert(result.object?["TotalIn"] != nil &&
                    result.object?["TotalOut"] != nil &&
                    result.object?["RateIn"] != nil &&
                    result.object?["RateOut"] != nil )
                
                dispatchGroup.leave()
            }
        }
        
        tester(stats)
        
    }
    
    func testLog() {
        let log = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            let updateHandler = { (data: Data) -> Bool in
                print("Got an update. Closing.")
                return false
            }
            
            try api.log(updateHandler) {
                log in
                
                for entry in log {
                    print(entry)
                }
                dispatchGroup.leave()
            }
        }
        
        //tester(log)
        
    }
    
    func testdns() {
        let dns = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api       = try IpfsApi(addr: "/ip4/\(self.hostString)/tcp/\(self.hostPort)")
            let domain    = "ipfs.io"
            try api.dns(domain) {
                domainString in
                
                print("Domain: ",domainString)
//                if domainString != "/ipfs/QmcQBvKTP8R7p8DgLEtKuoeuz1BBbotGpmofEFBEYBfc97" {
//                    XCTFail("domain string mismatch.")
//                }
                dispatchGroup.leave()
            }
        }
        
        tester(dns)
    }
    
    func testMount() {
        let mount = { (dispatchGroup: DispatchGroup) throws -> Void in
            let api       = try IpfsApi(addr: "/ip4/\(self.hostString)/tcp/\(self.hostPort)")
            
            try api.mount() {
                result in
                
                print("Mount got", result)
                XCTAssert(  result.object?["IPFS"]?.string == "/ipfs" &&
                            result.object?["IPNS"]?.string == "/ipns")
                dispatchGroup.leave()
            }
            
        }
        
        tester(mount)
    }
    
    func testResolveIpfs() {
        let resolve = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api       = try IpfsApi(addr: "/ip4/\(self.hostString)/tcp/\(self.hostPort)")
            let multihash = try fromB58String("QmXsnbVWHNnLk3QGfzGCMy1J9GReWN7crPvY1DKmFdyypK")
            
            try api.resolve("ipfs", hash: multihash, recursive: false) {
                result in
				XCTAssert(result.object?["Path"]?.string == "/ipfs/QmW2WQi7j6c7UgJTarActp7tDNikE4B2qXtFCfLPdsgaTQ")
//                print("Resolve IPFS got", result)
                dispatchGroup.leave()
            }
        }
        
        tester(resolve)
    }
    
    func testResolveIpns() {
        let resolve = { (dispatchGroup: DispatchGroup) throws -> Void in
            
            let api       = try IpfsApi(addr: "/ip4/\(self.hostString)/tcp/\(self.hostPort)")
            //let api = try IpfsApi(addr: "/ip4/ipfs.infura.io/tcp/5001")
            let multihash = try fromB58String(self.nodeIdString)
            
            
            try api.resolve("ipns", hash: multihash, recursive: false) {
                result in
                
                XCTAssert(result.object?["Path"]?.string == "/ipfs/QmeXS82nS8YDXQpiqFeT4gCHc1HGoxZe5zH6Srj4HhkiFy")
                
                dispatchGroup.leave()
            }
        }
        
        tester(resolve)
    }
    

 
    
    func testAdd() {
        
        let add = { (dispatchGroup: DispatchGroup) throws -> Void in
//            let filePaths = [   "file:///Users/teo/tmp/outstream.txt",
//                                "file:///Users/teo/tmp/notred.png",
//                                "file:///Users/teo/tmp/F4115_WU5086.jpeg"]
//            let filePaths = [   "file:///Users/teo/Library/Services/FilesToIpfs.workflow"]
            let filePaths = [   "file:///Users/joohan/addtest"]

            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            
            print(filePaths)
            
            try api.add(filePaths) {
                result in
                
                /// Subtract one because last element is an empty directory to ignore
                let resultCount = result.count
                
                //XCTAssert(resultCount == filePaths.count)
                
                //for mt in result {
                for i in 0..<resultCount {
					//XCTAssert(result[i].name! == filePaths[i].components(separatedBy: "/").last)
					//print("Name:", filePaths[i].components(separatedBy: "/").last)
                    print("Hash:", b58String(result[i].hash!))
                }
                
                dispatchGroup.leave()
            }
        }
        
        tester(add)
    }
    
    
    func testRefs() {
        let refs = { (dispatchGroup: DispatchGroup) throws -> Void in
            let multihash = try fromB58String("QmXsnbVWHNnLk3QGfzGCMy1J9GReWN7crPvY1DKmFdyypK")
            let api = try IpfsApi(host: self.hostString, port: self.hostPort)
            
            try api.refs(multihash, recursive: false) {
                result in
                
                XCTAssert(  result.count == 2 &&
                            b58String(result[0]) == "QmZX6Wrte3EqkUCwLHqBbuDhmH5yqPurNNTxKQc4NFfDxT" &&
                            b58String(result[1]) == "QmaLB324wDRKEJbGGr8FWg3qWnpTxdc2oEKDT62qhe8tMR" )
//                for mh in result {
//                    print(b58String(mh))
//                }
                
                dispatchGroup.leave()
            }
        }
        tester(refs)
    }
    
    
    
    /// Utility functions
    
    func tester(_ test: (_ dispatchGroup: DispatchGroup) throws -> Void) {
        
        let group = DispatchGroup()
        
        group.enter()
        
        do {
            /// Perform the test.
            try test(group)
            
        } catch  {
            XCTFail("tester error: \(error)")
        }
        
        group.wait(timeout: DispatchTime.distantFuture)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
/** Template for test
do {
    let group = dispatch_group_create()
    dispatch_group_enter(group)

    let api = try IpfsApi(host: self.hostString, port: self.hostPort)
    let multihash = try fromB58String("QmWPmgXnRn81QMPpfRGQ9ttQXsgfe2YwQxJ9PEB99E6KJh")

    try api.??(??) {
        result in
        print("Bingo")

        dispatch_group_leave(group)
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
} catch {
    print("TestBaseCommands error: ",error)
    XCTFail()
}
*/
