//
//  PodcastCollectionDatasource.swift
//  Darwin-iOS
//
//  Created by Zenos on 7/7/18.
//  Copyright © 2018 Zixia. All rights reserved.
//

import UIKit

@objc
protocol PodcastSelectionObserver: class {
	func selected(_ podcast: DataStack, on: IndexPath)
}

class PodcastCollectionDatasource: NSObject {
	
	var dataStack: DataStack
	var managedCollection: UICollectionView
	
	init(collectionView: UICollectionView) {
		
		dataStack = DataStack()
		managedCollection = collectionView
		super.init()
		managedCollection.dataSource = self
	}
	
	private var selectionObservers = NSHashTable<PodcastSelectionObserver>.weakObjects()
	func registerSelectionObserver(observer: PodcastSelectionObserver) {
		selectionObservers.add(observer)
	}
	
	func podcast(at index: Int) -> Podcast {
		let realindex = index % dataStack.allPods.count
		return dataStack.allPods[realindex]
	}
	
	func load() {
		guard let homeUrl = URL(string: "http://ec2-18-219-52-58.us-east-2.compute.amazonaws.com/api_home") else { return }
		URLSession.shared.dataTask(with: homeUrl) { (data, response
			, error) in
			
			guard let data = data else { return }
			do {
				let decoder = JSONDecoder()
				let apiHomeData = try decoder.decode(Array<Podcast>.self, from: data)
				print(apiHomeData, "+++++++++\n")
				DispatchQueue.main.async {
					self.dataStack.load2(podcasts: apiHomeData) { [weak self] success in
						self?.managedCollection.reloadData()
					}
				}
			} catch let err {
				print("Error, Couldnt load api data", err)
			}
			}.resume()
	}
}

// MARK: - UICollectionViewDataSource
extension PodcastCollectionDatasource: UICollectionViewDataSource,UICollectionViewDelegate {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return dataStack.allPods.count
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let screenWidth = UIScreen.main.bounds.width
		let scaleFactor = (screenWidth / 3) - 6
		
		return CGSize(width: scaleFactor, height: scaleFactor)
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PodcastCell", for: indexPath) as? PodcastCell else {
			assertionFailure("Should have dequeued PodcastCell here")
			return UICollectionViewCell()
		}
		return configured(cell, at: indexPath)
	}
	
	func configured(_ cell: PodcastCell, at indexPath: IndexPath) -> PodcastCell {
		let ipod = podcast(at: indexPath.row)
		cell.podcastTitle.text = ipod.title
		cell.artistName.text = ipod.artist
		ipod.loadPodcastImage { image in
			cell.coverArt.image = image
		}
		return cell
	}
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		for observer:PodcastSelectionObserver in self.selectionObservers.allObjects {
			observer.selected(dataStack, on: indexPath)
		}
	}
	
	
}
