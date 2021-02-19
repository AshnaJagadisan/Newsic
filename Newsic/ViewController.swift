//
//  ViewController.swift
//  Newsic
//
//  Created by Ashna on 2021-02-16.
//  Copyright © 2021 Ashna. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController, UISearchBarDelegate {
    
    let musicPlayer = MPMusicPlayerApplicationController.systemMusicPlayer
    
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var generateButton: UIButton!
    @IBOutlet weak var topVStack: UIStackView!
    @IBOutlet weak var bottomVStack: UIStackView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var albumCover: UIImageView!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        playPauseButton.layer.cornerRadius = 20.0
        nextButton.layer.cornerRadius = 20.0
        generateButton.layer.cornerRadius = 20.0
        topVStack.layer.cornerRadius = 20.0
        bottomVStack.layer.cornerRadius = 20.0
        albumCover.layer.cornerRadius = 10.0
        
        topVStack.layer.masksToBounds = true
        topVStack.layer.shadowColor = UIColor.black.cgColor
        topVStack.layer.shadowOpacity = 0.20
        topVStack.layer.shadowOffset = CGSize(width: 0, height: 0)
        topVStack.layer.shadowRadius = 20
        
        bottomVStack.layer.masksToBounds = true
        bottomVStack.layer.shadowColor = UIColor.black.cgColor
        bottomVStack.layer.shadowOpacity = 0.10
        bottomVStack.layer.shadowOffset = CGSize(width: 0, height: 0)
        bottomVStack.layer.shadowRadius = 20
        
        nextButton.addTarget(self,
                             action: #selector(holdReleased),
                             for: .touchUpInside)
        nextButton.addTarget(self,
                             action: #selector(heldDown),
                             for: .touchDown)
        nextButton.addTarget(self,
                             action: #selector(heldAndReleased),
                             for: .touchDragExit)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(nowPlayingItemChanged),
                                               name: NSNotification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
                                               object: musicPlayer)
        
        searchBar.delegate = self
        
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    @objc func heldDown() {
        nextButton.backgroundColor = UIColor.quaternarySystemFill
    }
    
    @objc func holdReleased() {
        nextButton.backgroundColor = UIColor.clear
    }
    
    @objc func heldAndReleased() {
        nextButton.backgroundColor = UIColor.quaternarySystemFill
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc func nowPlayingItemChanged(notification: NSNotification) {
        if musicPlayer.nowPlayingItem != nil {
            songTitle.isHidden = false
            artistName.isHidden = false
            setNowPlayingInfo()
        }
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.resignFirstResponder()
    }
    
    
    @IBAction func generateButtonTapped(_ sender: UIButton) {
        let inputSong = searchBar.text
        searchBar.resignFirstResponder()
        
        MPMediaLibrary.requestAuthorization { (status) in
            if status == .authorized {
                DispatchQueue.main.async {
                    self.playMusic(song: inputSong!)
                    self.playPauseButton.backgroundColor = UIColor.clear
                    self.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                    self.playPauseButton.tintColor = UIColor.systemRed
                }
            }
        }
    }
    
    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        if musicPlayer.playbackState == .paused {
            musicPlayer.play()
            playPauseButton.backgroundColor = UIColor.clear
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            playPauseButton.tintColor = UIColor.systemRed
            
        } else if musicPlayer.playbackState == .playing {
            musicPlayer.pause()
            playPauseButton.backgroundColor = UIColor.quaternarySystemFill
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            playPauseButton.tintColor = UIColor.systemGreen
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: UIButton?) {
        musicPlayer.skipToNextItem()
        //setAlbumCover()
    }
    
    func playMusic(song: String) {
        musicPlayer.stop()
        
        // briefly play inputted song to obtain genre
        let query = MPMediaQuery()
        let predicate = MPMediaPropertyPredicate(value: song, forProperty: MPMediaItemPropertyTitle, comparisonType: .contains)
        query.addFilterPredicate(predicate)
    
        musicPlayer.setQueue(with: query)
        musicPlayer.play()
        let genre = musicPlayer.nowPlayingItem?.genre
        musicPlayer.stop()
        query.removeFilterPredicate(predicate)
        
        // play random song from same genre
        let newQuery = MPMediaQuery()
        let genrePredicate = MPMediaPropertyPredicate(value: genre, forProperty: MPMediaItemPropertyGenre)
        newQuery.addFilterPredicate(genrePredicate)
    
        musicPlayer.setQueue(with: newQuery)
        musicPlayer.shuffleMode = .songs
        musicPlayer.play()
    }
    
    func setNowPlayingInfo() {
        //.image(at: albumCover.bounds.size)

        DispatchQueue.main.async {
            let currentSong = self.musicPlayer.nowPlayingItem
            let image = currentSong?.artwork?.image(at: CGSize(width: 310, height: 310))
            self.albumCover.image = image
            if image != nil {
                self.view.backgroundColor = UIColor(patternImage: image!)
            }
            self.songTitle.text = currentSong?.title
            self.artistName.text = currentSong?.artist
        }
    }
}

