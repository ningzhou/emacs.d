(setq w3m-coding-system 'utf-8
      w3m-file-coding-system 'utf-8
      w3m-file-name-coding-system 'utf-8
      w3m-input-coding-system 'utf-8
      w3m-output-coding-system 'utf-8
      ;; emacs-w3m will test the ImageMagick support for png32
      ;; and create files named "png32:-" everywhere
      w3m-imagick-convert-program nil
      w3m-terminal-coding-system 'utf-8
      w3m-use-cookies t
      w3m-cookie-accept-bad-cookies t
      w3m-home-page "http://www.google.com.au"
      w3m-command-arguments       '("-F" "-cookie")
      w3m-mailto-url-function     'compose-mail
      browse-url-browser-function 'w3m
      mm-text-html-renderer       'w3m
      w3m-use-toolbar t
      ;; show images in the browser
      ;; setq w3m-default-display-inline-images t
      ;; w3m-use-tab     nil
      w3m-confirm-leaving-secure-page nil
      w3m-search-default-engine "g"
      w3m-key-binding 'info)

(defun w3m-get-url-from-search-engine-alist (k l)
  (let (rlt)
    (if (listp l)
      (if (string= k (caar l))
          (setq rlt (nth 1 (car l)))
        (setq rlt (w3m-get-url-from-search-engine-alist k (cdr l)))))
    rlt))

;; C-u S g RET <search term> RET in w3m
(setq w3m-search-engine-alist
      '(("g" "http://www.google.com.au/search?q=%s" utf-8)
        ;; stackoverflow search
        ("q" "http://www.google.com.au/search?q=%s+site:stackoverflow.com" utf-8)
        ;; elisp code search
        ("s" "http://www.google.com.au/search?q=%s+filetype:el"  utf-8)
        ;; wikipedia
        ("w" "http://en.wikipedia.org/wiki/Special:Search?search=%s" utf-8)
        ;; online dictionary
        ("d" "http://dictionary.reference.com/search?q=%s" utf-8)
        ;; java google search
        ("java" "https://www.google.com.au/search?q=java+%s" utf-8)
        ;; financial dictionary
        ("f" "http://financial-dictionary.thefreedictionary.com/%s" utf-8)
        ;; javascript search on mozilla.org
        ("j" "http://www.google.com.au/search?q=%s+site:developer.mozilla.org" utf-8)))

(defun w3m-set-url-from-search-engine-alist (k l url)
    (if (listp l)
      (if (string= k (caar l))
          (setcdr (car l) (list url))
        (w3m-set-url-from-search-engine-alist k (cdr l) url))))

(defvar w3m-global-keyword nil
  "`w3m-display-hook' must search current buffer with this keyword twice if not nil")

(defun w3m-guess-keyword (&optional encode-space-with-plus)
  (unless (featurep 'w3m) (require 'w3m))
  (let (keyword encoded-keyword)
    (setq keyword (if (region-active-p)
             (buffer-substring-no-properties (region-beginning) (region-end))
           (read-string "Enter keyword:")))
    ;; some search requires plus sign to replace space
    (setq encoded-keyword
          (w3m-url-encode-string (setq w3m-global-keyword keyword)))
    (if encode-space-with-plus
        (replace-regexp-in-string "%20" " " encoded-keyword)
      encoded-keyword)))

(defun w3m-customized-search-api (search-engine &optional encode-space-with-plus)
  (unless (featurep 'w3m) (require 'w3m))
  (w3m-search search-engine (w3m-guess-keyword encode-space-with-plus)))

(defun w3m-stackoverflow-search ()
  (interactive)
  (w3m-customized-search-api "q"))

(defun w3m-java-search ()
  (interactive)
  (w3m-customized-search-api "java"))

(defun w3m-google-search ()
  "Google search keyword"
  (interactive)
  (w3m-customized-search-api "g"))

(defun w3m-google-by-filetype ()
  "Google search 'keyword filetype:file-extension'"
  (interactive)
  (unless (featurep 'w3m) (require 'w3m))
  (let ((old-url (w3m-get-url-from-search-engine-alist "s" w3m-search-engine-alist))
        new-url)
    ;; change the url to search current file type
    (when buffer-file-name
      (setq new-url (replace-regexp-in-string
                     "filetype:.*"
                     (concat "filetype:" (file-name-extension buffer-file-name))
                     old-url))
      (w3m-set-url-from-search-engine-alist "s" w3m-search-engine-alist new-url))
    (w3m-customized-search-api "s")
    ;; restore the default url
    (w3m-set-url-from-search-engine-alist "s" w3m-search-engine-alist old-url)))

(defun w3m-search-financial-dictionary ()
  "Search financial dictionary"
  (interactive)
  (w3m-customized-search-api "f" t))

(defun w3m-search-js-api-mdn ()
  "Search at Mozilla Developer Network (MDN)"
  (interactive)
  (w3m-customized-search-api "j"))

(defun w3m-mode-hook-setup ()
  (w3m-lnum-mode 1))

(add-hook 'w3m-mode-hook 'w3m-mode-hook-setup)

; {{ Search using external browser
(setq browse-url-generic-program
      (cond
       (*is-a-mac* "open")
       (*linux* (executable-find "firefox"))
       ))
(setq browse-url-browser-function 'browse-url-generic)

;; use external browser to search programming stuff
(defun w3mext-hacker-search ()
  "Search on all programming related sites in external browser"
  (interactive)
  (let ((keyword (w3m-guess-keyword)))
    ;; google
    (browse-url-generic (concat "http://www.google.com.au/search?hl=en&q=%22"
                                keyword
                                "%22"
                                (if buffer-file-name
									(concat "+filetype%3A" (file-name-extension buffer-file-name))
									"")))
    ;; stackoverflow.com
    (browse-url-generic (concat "http://www.google.com.au/search?hl=en&q="
                                keyword
                                "+site:stackoverflow.com" ))
    ;; koders.com
    (browse-url-generic (concat "http://code.ohloh.net/search?s=\""
                                keyword
                                "\"&browser=Default&mp=1&ml=1&me=1&md=1&filterChecked=true" ))
    ))
;; }}

(defun w3mext-open-link-or-image-or-url ()
  "Opens the current link or image or current page's uri or any url-like text under cursor in firefox."
  (interactive)
  (let (url)
    (when (or (string= major-mode "w3m-mode") (string= major-mode "gnus-article-mode"))
      (setq url (w3m-anchor))
      (if (or (not url) (string= url "buffer://"))
          (setq url (or (w3m-image) w3m-current-url))))
    (browse-url-generic (if url url (car (browse-url-interactive-arg "URL: "))))
    ))

(defun w3mext-open-with-mplayer ()
  (interactive)
  (let (url cmd str)
    (when (or (string= major-mode "w3m-mode") (string= major-mode "gnus-article-mode"))
      (setq url (w3m-anchor))
      (unless url
        (save-excursion
          (goto-char (point-min))
          (when (string-match "^Archived-at: <?\\([^ <>]*\\)>?" (setq str (buffer-substring-no-properties (point-min) (point-max))))
            (setq url (match-string 1 str)))))

      (setq cmd (format "%s -cache 2000 %s &" (my-guess-mplayer-path) url))
      (when (or (not url) (string= url "buffer://"))
        (setq url (w3m-image))
        ;; cache 2M data and don't block UI
        (setq cmd (my-guess-image-viewer-path url t))))
    (if url (shell-command cmd))))

(defun w3mext-subject-to-target-filename ()
  (let (rlt str)
    (save-excursion
      (goto-char (point-min))
      ;; first line in email could be some hidden line containing NO to field
      (setq str (buffer-substring-no-properties (point-min) (point-max))))
    ;; (message "str=%s" str)
    (if (string-match "^Subject: \\(.+\\)" str)
        (setq rlt (match-string 1 str)))
    ;; clean the timestamp at the end of subject
    (setq rlt (replace-regexp-in-string "[ 0-9_.'/-]+$" "" rlt))
    (setq rlt (replace-regexp-in-string "'s " " " rlt))
    (setq rlt (replace-regexp-in-string "[ ,_'/-]+" "-" rlt))
    rlt))

(defun w3mext-download-rss-stream ()
  (interactive)
  (let (url cmd)
    (when (or (string= major-mode "w3m-mode") (string= major-mode "gnus-article-mode"))
      (setq url (w3m-anchor))
      (cond
       ((or (not url) (string= url "buffer://"))
        (message "This link is not video/audio stream."))
       (t
        (setq cmd (format "curl -L %s > %s.%s"  url (w3mext-subject-to-target-filename) (file-name-extension url)))
        (kill-new cmd)
        (if (fboundp 'simpleclip-set-contents)
            (simpleclip-set-contents cmd))
        (message "%s => clipd/kill-ring" cmd))))
    ))

(eval-after-load 'w3m
  '(progn
     (define-key w3m-mode-map (kbd "C-c b") 'w3mext-open-link-or-image-or-url)
     (add-hook 'w3m-display-hook
               (lambda (url)
                 (let ((title (or w3m-current-title url)))
                   (when w3m-global-keyword
                     ;; search keyword twice, first is url, second is your input,
                     ;; third is actual result
                     (goto-char (point-min))
                     (search-forward-regexp (replace-regexp-in-string " " ".*" w3m-global-keyword)  (point-max) t 3)
                     ;; move the cursor to the beginning of word
                     (backward-char (length w3m-global-keyword))
                     ;; cleanup for next search
                     (setq w3m-global-keyword nil))
                   ;; rename w3m buffer
                   (rename-buffer
                    (format "*w3m: %s*"
                            (substring title 0 (min 50 (length title)))) t))))))

;; search and browse using system default web browser
(require 'webjump)
(setq webjump-sites
      '(
        ;; search engine
        ("google" . [simple-query "www.google.com" "www.google.com/search?q=" ""])
        ("baidu" . [simple-query "www.baidu.com" "www.baidu.com/s?wd=" ""])
        ("bing" . [simple-query "cn.bing.com" "cn.bing.com/search?q=" ""])
        ("gist" . [simple-query "gist.github.com" "gist.github.com/gists/search?q=" ""])
        ;;("google" . [simple-query "www.google.com" "203.208.46.146/search?q=" ""])
        ("duckduckgo" . [simple-query "duckduckgo.com" "duckduckgo.com/?q=" ""])
        ("yahoo" . [simple-query "au.search.yahoo.com" "au.search.yahoo.com/yhs/search?p=" ""])
        ("iciba" . [simple-query "www.iciba.com" "www.iciba.com/" ""])
        ("wiki" . [simple-query "en.wikipedia.org" "en.wikipedia.org/w/index.php?search=" ""])
        ;; --8<------------------ search engine ------------------------>8--

        ;; --8<------------------ ebook ------------------------>8--
        ("book-shupeng" . [simple-query "www.shupeng.com" "www.shupeng.com/search/" ""])
        ("book-coay" . [simple-query "www.coay.com" "www.coay.com/search.php?key=" ""])
        ("book-wenku" . [simple-query "wenku.baidu.com" "wenku.baidu.com/search?word=" ""])
        ("book-iask" . [simple-query "ishare.iask.sina.com.cn" "ishare.iask.sina.com.cn/search.php?key=" ""])
        ("book-douban" . [simple-query "book.douban.com" "book.douban.com/subject_search?cat=1001&search_text=" ""])
        ("book-yinian" . "www.inien.com/w/#/Index")
        ("book-ppurl" . [simple-query "www.ppurl.com" "www.ppurl.com/" ""])
        ;; --8<------------------ ebook ------------------------>8--

        ;; --8<------------------ paper ------------------------>8--
        ("paper-citeseerx" . [simple-query "citeseerx.ist.psu.edu" "citeseerx.ist.psu.edu/search?submit=Search&sort=rel&q=" ""])
        ;; --8<------------------ paper ------------------------>8--

        ;; --8<------------------ life ------------------------>8--
        ;;TODO: keyword need to be escaped
        ("taobao" . [simple-query "www.taobao.com" "s.taobao.com/search?q=" ""])
        ("movie-douban" . [simple-query "movie.douban.com" "movie.douban.com/subject_search?cat=1002&search_text=" ""])
        ("music-douban" . [simple-query "music.douban.com" "music.douban.com/subject_search?cat=1003&search_text=" ""])
        ;; --8<------------------ life ------------------------>8--

        ;; --8<------------------ emacs ------------------------>8--
        ("emacswiki" . [simple-query "www.emacswiki.org/emacs" "www.google.com/cse?cx=004774160799092323420%3A6-ff2s0o6yi&sa=Search&siteurl=www.emacswiki.org%2Femacs%2F&q=" ""])
        ;; --8<------------------ emacs ------------------------>8--

        ;; --8<------------------ programming ------------------------>8--
        ("linux apps" . "www.appwatch.com/Linux/")
        ("erlang manual" . "www.erlang.org/doc/man/erlang.html")
        ;; --8<------------------ personal ------------------------>8--

        ;; --8<------------------ misc ------------------------>8--
        ("slideshare" . "www.slideshare.net")
        ;; --8<------------------ misc ------------------------>8--
        ))
;; --8<-------------------------- separator ------------------------>8--
;; C-u super j: browse webjump link in the way of w3m, instead of default web browser
(defun webjump (use-w3m-p)
  "The behaviour is different from standard webjump in the following:
 - Users can input web host and search keyword in a single inpute, instead of two
 - User can choose whether to view link in w3m or not, by given the use-w3m-p parameter
 - Set the default web host as google
 - The matching of web host is case insensitive
 "
  (interactive "P")
  (let* ((completion-ignore-case t) user-input
         search-engine search-keywords item name expr)
    ;; read customer input for search engine and search keywords, like "google emacs webjump"
    (make-local-variable 'minibuffer-local-completion-map)
    (define-key minibuffer-local-completion-map " " nil)
    (setq user-input (split-string
                      (completing-read "WebJump to site: " webjump-sites nil nil "google ")
                      " "))
    (setq search-engine (car user-input))
    (setq search-keywords (mapconcat #'identity
                                     (cdr user-input) " "))
    (setq item (assoc-string search-engine webjump-sites nil))
    (setq name (car item))
    (setq expr (cdr item))
    (when use-w3m-p
      (make-local-variable 'browse-url-browser-function)
      (setq browse-url-browser-function 'w3m-browse-url))
    (browse-url (webjump-url-fix
                 (cond ((not expr) "")
                       ((stringp expr) expr)
                       ((vectorp expr) (webjump-builtin-keywords expr name search-keywords))
                       ((listp expr) (eval expr))
                       ((symbolp expr)
                        (if (fboundp expr)
                            (funcall expr name)
                          (error "WebJump URL function \"%s\" undefined"
                                 expr)))
                       (t (error "WebJump URL expression for \"%s\" invalid"
                                 name)))))))

(defun webjump-builtin-keywords (expr name &optional keywords)
  "If keywords are given, no need to ask users' input"
  (if (and keywords (not (string-equal keywords "")))
      (concat (aref expr 2) (webjump-url-encode keywords) (aref expr 3))
    (webjump-builtin expr name)))
;; --8<-------------------------- separator ------------------------>8--
;;(setq browse-url-generic-program "/usr/bin/firefox")
;;set google chrome as the default brower
(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "google-chrome")


(provide 'init-emacs-w3m)
