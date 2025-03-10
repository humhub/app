import receive_sharing_intent

class ShareViewController: RSIShareViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.alpha = 0
        view.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.setAnimationsEnabled(false)  // Disable any potential fade-in
    }

    override func shouldAutoRedirect() -> Bool {
        return true
    }
}

