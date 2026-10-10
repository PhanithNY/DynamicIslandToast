import DynamicIslandToast
import UIKit

final class ExamplesViewController: UITableViewController {
  private let durationControl = UISegmentedControl(items: ["2 seconds", "4 seconds", "Until tapped"])
  private lazy var durationCell: UITableViewCell = {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    durationControl.translatesAutoresizingMaskIntoConstraints = false
    cell.contentView.addSubview(durationControl)
    NSLayoutConstraint.activate([
      durationControl.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
      durationControl.leadingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.leadingAnchor),
      durationControl.trailingAnchor.constraint(equalTo: cell.contentView.layoutMarginsGuide.trailingAnchor),
      durationControl.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
    ])
    return cell
  }()

  init() {
    super.init(style: .insetGrouped)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Toast Examples"
    navigationController?.navigationBar.prefersLargeTitles = true
    durationControl.selectedSegmentIndex = 1
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ExampleCell")
  }

  private var dismissDelay: TimeInterval? {
    switch durationControl.selectedSegmentIndex {
    case 0: return 2
    case 1: return 4
    default: return nil
    }
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    section == 0 ? 1 : ToastExample.allCases.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    section == 0 ? "Dismissal" : "Try a toast"
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    if section == 0 {
      return "Tap outside a toast to dismiss it at any time."
    }
    return "Best experienced on an iPhone with Dynamic Island. Each example uses the local DynamicIslandToast package."
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard indexPath.section == 1 else { return durationCell }
    let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath)
    let example = ToastExample.allCases[indexPath.row]
    var content = cell.defaultContentConfiguration()
    content.text = example.title
    content.secondaryText = example.detail
    content.image = UIImage(systemName: example.symbolName)
    content.imageProperties.tintColor = .systemIndigo
    cell.contentConfiguration = content
    cell.accessoryType = .disclosureIndicator
    cell.accessibilityIdentifier = "example.\(example)"
    cell.accessibilityTraits.insert(.button)
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard indexPath.section == 1,
          presentedViewController == nil,
          !isBeingDismissed else { return }

    let toast = ToastViewController(example: ToastExample.allCases[indexPath.row])
    presentDynamicIsland(toast, dismissAfterDelayed: dismissDelay)
  }
}
