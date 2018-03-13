//
//  SystemVolumeManager.swift
//
//  Copyright (c) 2016-Present Sachin Patel (http://gizmosachin.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import AVFoundation

@objc internal protocol SystemVolumeObserver {
	func volumeChanged(to volume: Float)
}

internal final class SystemVolumeManager: NSObject {
	fileprivate let observers: NSHashTable<SystemVolumeObserver>
	
	internal override init() {
		observers = NSHashTable<SystemVolumeObserver>.weakObjects()
		
		super.init()
		
		startObservingSystemVolumeChanges()
		startObservingApplicationStateChanges()
	}
	
	deinit {
		observers.removeAllObjects()
		
		stopObservingSystemVolumeChanges()
		stopObservingApplicationStateChanges()
	}

	public func volumeChanged(to volume: Float) {
		for case let observer as SystemVolumeObserver in observers.objectEnumerator() {
			observer.volumeChanged(to: volume)
		}
	}
}

// System Volume Changes
internal extension SystemVolumeManager {
	internal func startObservingSystemVolumeChanges() {
		do {
			try! AVAudioSession.sharedInstance().setActive(true)
		}
		
		// Observe system volume changes
		AVAudioSession.sharedInstance().addObserver(self, forKeyPath: #keyPath(AVAudioSession.outputVolume), options: [.old, .new], context: nil)
	}
	
	internal func stopObservingSystemVolumeChanges() {
		// Stop observing system volume changes
		AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: #keyPath(AVAudioSession.outputVolume))
	}
	
	/// Observe changes in volume.
	///
	/// This method is called when the user presses either of the volume buttons.
	override internal func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		let volume = AVAudioSession.sharedInstance().outputVolume
		volumeChanged(to: volume)
	}
}

// Application State Changes
internal extension SystemVolumeManager {
	internal func startObservingApplicationStateChanges() {
		// Add application state observers
		NotificationCenter.default.addObserver(self, selector: #selector(SystemVolumeManager.applicationWillResignActive(notification:)), name: .UIApplicationWillResignActive, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(SystemVolumeManager.applicationDidBecomeActive(notification:)), name: .UIApplicationDidBecomeActive, object: nil)
	}
	
	internal func stopObservingApplicationStateChanges() {
		// Remove application state observers
		NotificationCenter.default.removeObserver(self, name: .UIApplicationWillResignActive, object: nil)
		NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
	}
	
	/// Observe when the application background state changes.
	@objc internal func applicationWillResignActive(notification: Notification) {
		// Stop observing volume while in the background
		stopObservingSystemVolumeChanges()
	}
	
	@objc internal func applicationDidBecomeActive(notification: Notification) {
		// Restart session after becoming active
		startObservingSystemVolumeChanges()
	}
}

// Volume Manager Observers
internal extension SystemVolumeManager {
	func addObserver(_ observer: SystemVolumeObserver) {
		observers.add(observer)
	}
	
	func removeObserver(_ observer: SystemVolumeObserver) {
		observers.remove(observer)
	}
}