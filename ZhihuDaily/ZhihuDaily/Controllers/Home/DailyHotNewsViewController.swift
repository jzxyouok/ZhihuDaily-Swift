//
//  DailyHotNewsViewController.swift
//  ZhihuDaily
//
//  Created by KiBen on 17/1/6.
//  Copyright © 2017年 YioMidd. All rights reserved.
//

import UIKit
import SnapKit

class DailyHotNewsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NewsImageHeaderViewDelegate, SDCycleScrollViewDelegate {
    // MARK: Private Property
    fileprivate let originOffset: CGFloat = -64.0
    fileprivate let scrollDistance: CGFloat = 185.0
    fileprivate var oldContentSizeHeight: CGFloat = 0.0
    fileprivate var newsDateString: String = Date().newsDateString
    fileprivate var hotNewsSource: Array<[String : Any]> = Array<[String : Any]>()
    fileprivate var cycleScrollView: SDCycleScrollView?
    fileprivate var statusBarStyle: UIStatusBarStyle = .lightContent 
    fileprivate var statusBarStateHide: Bool = true
    fileprivate var titleView = NavTitleView(frame: CGRect(x: 0, y: 0, width: 120, height: 30))
    fileprivate let maxContentOffsetY: CGFloat = -120.0
    
    fileprivate lazy var headerView: NewsImageHeaderView = {
        let headerViewHeight: CGFloat = 154
        self.cycleScrollView = SDCycleScrollView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: ym_ScreenWidth, height: headerViewHeight)), delegate: self, placeholderImage: nil) as SDCycleScrollView
        self.cycleScrollView?.backgroundColor = UIColor.clear
        self.cycleScrollView?.pageControlStyle = SDCycleScrollViewPageContolStyleAnimated
        self.cycleScrollView?.autoScrollTimeInterval = 6.0;
        self.cycleScrollView?.pageControlStyle = SDCycleScrollViewPageContolStyleClassic
        self.cycleScrollView?.bannerImageViewContentMode = .scaleAspectFill
        self.cycleScrollView?.titleLabelTextFont = CycleViewTitleFont
        self.cycleScrollView?.titleLabelBackgroundColor = UIColor.clear
        self.cycleScrollView?.titleLabelHeight = 100
        
        let headerView: NewsImageHeaderView = NewsImageHeaderView(size: CGSize(width: ym_ScreenWidth, height: headerViewHeight), maxContentOffsetY: self.maxContentOffsetY, containSubView: self.cycleScrollView!)
        headerView.delegate = self
        return headerView
    }()
    
    fileprivate lazy var newsTableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(NewsItemCell.self, forCellReuseIdentifier: NSStringFromClass(NewsItemCell.self))
        tableView.register(NewsSectionDateCell.self, forCellReuseIdentifier: NSStringFromClass(NewsSectionDateCell.self))
        tableView.tableHeaderView = self.headerView
        return tableView
    }()
    
    override var prefersStatusBarHidden: Bool {
        return statusBarStateHide
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleView.titleLabel.text = "今日热闻"
        self.navigationItem.titleView = titleView
        let leftBarButton = UIBarButtonItem(image: R.image.home_Icon(), style: .plain, target: self, action: #selector(self.showSlideView))
        leftBarButton.tintColor = UIColor.white
        self.navigationItem.leftBarButtonItem = leftBarButton
        view.addSubview(newsTableView)
        newsTableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        newsTableView.tableHeaderView = headerView
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeStatusBarApperance(_:)), name: .StatusBarApperanceChangeNotification, object: nil)
        
        // 提前加载数据
        loadHotNews()
        // 展示启动欢迎界面
        addLaunchView()
    }
}

// MARK: tableView dataSource
extension DailyHotNewsViewController {
    
    func numberOfSections(in tableView: UITableView) -> Int {
         return hotNewsSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let news = hotNewsSource[section][HotNewsListDataKeyStories] as! Array<[String : Any]>
        if section == 0 {
            return news.count
        }
        return news.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section != 0 {
            if indexPath.row == 0 {
                // 日期分隔的cell
                let dateCell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(NewsSectionDateCell.self), for: indexPath) as! NewsSectionDateCell
                let dateString = hotNewsSource[indexPath.section][HotNewsListDataKeyDate] as! String
                dateCell.configCellWithData(ym_FormateDateString(dateString))
                return dateCell
            }
            let itemCell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(NewsItemCell.self), for: indexPath) as! NewsItemCell
            let news = hotNewsSource[indexPath.section][HotNewsListDataKeyStories] as! Array<[String : Any]>
            itemCell.configCellWithData(news[indexPath.row - 1])
            return itemCell
        }else {
            let itemCell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(NewsItemCell.self), for: indexPath) as! NewsItemCell
            let news = hotNewsSource[indexPath.section][HotNewsListDataKeyStories] as! Array<[String : Any]>
            itemCell.configCellWithData(news[indexPath.row])
            return itemCell
        }
    }
}

// MARK: tableView delegate
extension DailyHotNewsViewController {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section > 0 {
            if indexPath.row == 0 {
                return 35
            }else {
                return 95
            }
        }
        return 95
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offSetY = scrollView.contentOffset.y
        if offSetY < originOffset {
            self.navigationController?.navigationBar.lt_setBackgroundColor(backgroundColor: NavBarColor.withAlphaComponent(0))
            let percent = (originOffset - offSetY) / (originOffset - maxContentOffsetY)
            titleView.refreshView.redraw(progress: percent)
            if offSetY <= maxContentOffsetY + 10 && !scrollView.isDragging && !titleView.refreshView.refresh{
                titleView.refreshView.refresh = true
                loadHotNews()
            }
        }else {
            let alpha = (offSetY - originOffset) / scrollDistance
            guard !(alpha >= 1.0) else {
                return
            }
            titleView.refreshView.redraw(progress: 0.0)
            self.navigationController?.navigationBar.lt_setBackgroundColor(backgroundColor: NavBarColor.withAlphaComponent(min(1.0, alpha)))
        }
        let heardView = newsTableView.tableHeaderView as! NewsImageHeaderView
        heardView.layoutHeaderViewWithScrollOffset(scrollView.contentOffset)
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        let offSetY = scrollView.contentOffset.y
        let contentSizeHeight = scrollView.contentSize.height
        if abs(offSetY) + 64 >= contentSizeHeight * 0.3 && oldContentSizeHeight != contentSizeHeight {
            // load the news before the date
            oldContentSizeHeight = contentSizeHeight
            HTTPRequestClient().send(HTTPRequest(url: url_newsBefore(newsDateString), method: .GET, parameters: nil), handler: { (response) in
                if let _ = response.rawData {
                    let pastNewsData = response.fetchDataWithReformer(HotNewsListReformer()) as! Dictionary<String, Any>
                    self.newsDateString = pastNewsData[HotNewsListDataKeyDate] as! String
                    self.hotNewsSource.append(pastNewsData)
                    self.newsTableView.reloadData()
                }
            })
        }
    }
}

// MARK: headerView delegate
extension DailyHotNewsViewController {
    
    func headerView(_ headerView: NewsImageHeaderView, lockScrollWithOffset maxOffset: CGFloat) {
        newsTableView.contentOffset.y = maxOffset
    }
}

// MARK: Private
extension DailyHotNewsViewController {
    
    // MARK: Network Request
    fileprivate func loadHotNews() {
        HTTPRequestClient().send(HTTPRequest(url: url_latestNews(), method: .GET, parameters: nil)) { (response) in
            self.titleView.refreshView.refresh = false
            if let _ = response.rawData {
                let hotNewsData = response.fetchDataWithReformer(HotNewsListReformer()) as! Dictionary<String, Any>
                self.refreshHotNews(hotNewsData)
                
                let hotNewsTopData = response.fetchDataWithReformer(HotNewsTopListReformer()) as! Dictionary<String, Any>
                self.refreshHotNewsTop(hotNewsTopData)
            }
        }
    }
    
    private func refreshHotNews(_ sourceData: [String : Any]) {
        self.hotNewsSource.append(sourceData)
        self.newsTableView.reloadData()
    }
    
    private func refreshHotNewsTop(_ sourceData: [String : Any]) {
        var images = Array<String>()
        var titles = Array<String>()
        let stories = sourceData[HotNewsListDataKeyTopStories] as! Array<[String : Any]>
        for dict in stories {
            let imageUrlString = dict[HotNewsListDataKeyImage] as! String
            let title = dict[HotNewsListDataKeyTitle] as! String
            images.append(imageUrlString)
            titles.append(title)
        }
        self.cycleScrollView?.imageURLStringsGroup = images
        self.cycleScrollView?.titlesGroup = titles
    }
    
    // MARK: Add ChildVC
    fileprivate func addLaunchView() {
        let launchVC = LaunchViewController()
        let parentVC = AppDelegate.rootViewController()
        launchVC.showin(parent: parentVC)
    }
    
    // MARK: ChangeStatusBar Notification Method
    @objc fileprivate func changeStatusBarApperance(_ notification: Notification) {
        print("有通知来啦")
        switch notification.userInfo?.keys.first as! String{
        case let key where key == Notification.key.StatusBarStateHideNotificationUserInfoKey:
            statusBarStateHide = notification.userInfo?[key] as! Bool
        case let key where key == Notification.key.StatusBarStyleDefaultNotificationUserInfoKey:
            statusBarStyle = notification.userInfo?[key] as! UIStatusBarStyle
        case let key where key == Notification.key.StatusBarStyleLightContentNotificationUserInfoKey:
            statusBarStyle = notification.userInfo?[key] as! UIStatusBarStyle
        default: break
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // MARK: Button Actions
    @objc fileprivate func showSlideView() {
        self.mm_drawerController.toggle(.left, animated: true, completion: nil)
    }
}
