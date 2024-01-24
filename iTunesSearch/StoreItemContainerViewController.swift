
import UIKit

class StoreItemContainerViewController: UIViewController, UISearchResultsUpdating {
    
    @IBOutlet var tableContainerView: UIView!
    @IBOutlet var collectionContainerView: UIView!
    
    let searchController = UISearchController()
    let storeItemController = StoreItemController()
    
    var collectionViewDataSource: UICollectionViewDiffableDataSource<String, StoreItem>!
    var tableViewDataSource: UITableViewDiffableDataSource<String, StoreItem>!
    
    var itemSnapshot: NSDiffableDataSourceSnapshot<String, StoreItem> {
        var snapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
        
        snapshot.appendSections(["Results"])
        snapshot.appendItems(items)
        
        return snapshot
    }
    
    var items = [StoreItem]()

    let queryOptions = ["movie", "music", "software", "ebook"]
    
    // keep track of async tasks so they can be cancelled if appropriate.
    var searchTask: Task<Void, Never>? = nil
    var tableViewImageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
    var collectionViewImageLoadTasks: [IndexPath: Task<Void, Never>] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.automaticallyShowsSearchResultsController = true
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = ["Movies", "Music", "Apps", "Books"]
    }
    
    func configureTableViewDataSource(_ tableView: UITableView) {
        tableViewDataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { (tableView, indexPath, item) -> UITableViewCell? in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! ItemTableViewCell
            
            self.tableViewImageLoadTasks[indexPath]?.cancel()
            self.tableViewImageLoadTasks[indexPath] = Task {
                
                
                await cell.configure(for: item, storeItemController: self.storeItemController)
                
                
            }
            return cell
        })
        
        tableViewDataSource.apply(itemSnapshot)
    }
    
    func configureCollectionViewDataSource(_ collectionView: UICollectionView) {
        collectionViewDataSource = UICollectionViewDiffableDataSource<String, StoreItem>(collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Item", for: indexPath) as! ItemCollectionViewCell
            
            self.collectionViewImageLoadTasks[indexPath]?.cancel()
            self.collectionViewImageLoadTasks[indexPath] = Task {
                
                await cell.configure(for: item, storeItemController: self.storeItemController)
            }
            return cell
        })
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fetchMatchingItems), object: nil)
        perform(#selector(fetchMatchingItems), with: nil, afterDelay: 0.3)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let tableViewController = segue.destination as? StoreItemListTableViewController {
            configureTableViewDataSource(tableViewController.tableView)
        }
            if let collectionViewController = segue.destination as? StoreItemCollectionViewController {
                configureCollectionViewDataSource(collectionViewController.collectionView)
            }
        }
    
                
    @IBAction func switchContainerView(_ sender: UISegmentedControl) {
        tableContainerView.isHidden.toggle()
        collectionContainerView.isHidden.toggle()
    }
    
    @objc func fetchMatchingItems() {
        
        self.items = []
                
        let searchTerm = searchController.searchBar.text ?? ""
        let mediaType = queryOptions[searchController.searchBar.selectedScopeButtonIndex]
        
        // cancel existing task since we will not use the result
        searchTask?.cancel()
        searchTask = Task {
            if !searchTerm.isEmpty {
               
                collectionViewImageLoadTasks.values.forEach { task in task.cancel() }
                collectionViewImageLoadTasks = [:]
                tableViewImageLoadTasks.values.forEach { task in task.cancel() }
                tableViewImageLoadTasks = [:]
                
                // set up query dictionary
                let query = [
                    "term": searchTerm,
                    "media": mediaType,
                    "lang": "en_us",
                    "limit": "20"
                ]
                
                // use the item controller to fetch items
                do {
                    // use the item controller to fetch items
                    let items = try await storeItemController.fetchItems(matching: query)
                    if searchTerm == self.searchController.searchBar.text &&
                          mediaType == queryOptions[searchController.searchBar.selectedScopeButtonIndex] {
                        self.items = items
                        await tableViewDataSource.apply(itemSnapshot)
                        await collectionViewDataSource.apply(itemSnapshot, animatingDifferences: true)
                    }
                } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                   
                    // ignore cancellation errors
                } catch {
                    // otherwise, print an error to the console
                    print(error)
                }
              
            } else {
                await tableViewDataSource.apply(itemSnapshot)
                await collectionViewDataSource.apply(itemSnapshot, animatingDifferences: true)
            }
            searchTask = nil
        }
    }
    
}
