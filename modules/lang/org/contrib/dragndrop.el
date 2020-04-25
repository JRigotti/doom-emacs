;;; lang/org/contrib/dragndrop.el -*- lexical-binding: t; -*-
;;;###if (featurep! +dragndrop)

(use-package! org-download
  :commands
  org-download-dnd
  org-download-yank
  org-download-screenshot
  org-download-dnd-base64
  :init
  ;; HACK We add these manually so that org-download is truly lazy-loaded
  (pushnew! dnd-protocol-alist
            '("^\\(?:https?\\|ftp\\|file\\|nfs\\):" . +org-dragndrop-download-dnd-fn)
            '("^data:" . org-download-dnd-base64))
  (advice-add #'org-download-enable :override #'ignore)

  (after! org
    ;; A shorter link to attachments
    (+org-define-basic-link "download" 'org-attach-id-dir
      :image-data-fun #'+org-image-file-data-fn
      :requires 'org-download))
  :config
  (unless org-download-image-dir
    (setq org-download-image-dir (expand-file-name (or org-attach-id-dir "")
                                                   org-directory)))
  (setq org-download-link-format "[[download:%s]]\n"
        org-download-method 'attach
        org-download-heading-lvl nil
        org-download-timestamp "_%Y%m%d_%H%M%S"
        org-download-screenshot-method
        (cond (IS-MAC "screencapture -i %s")
              (IS-LINUX
               (cond ((executable-find "maim")  "maim -s %s")
                     ((executable-find "scrot") "scrot -s %s")
                     ((executable-find "gnome-screenshot") "gnome-screenshot -a -f %s")))))

  ;; Handle non-image files a little differently. Images should be inserted
  ;; as-is, as image previews. Other files, like pdfs or zips, should be linked
  ;; to, with an icon indicating the type of file.
  (defadvice! +org--dragndrop-insert-link-a (_link filename)
    "Produces and inserts a link to FILENAME into the document.

If FILENAME is an image, produce an download:%s path, otherwise use file:%s (with
an file icon produced by `+org-attach-icon-for')."
    :override #'org-download-insert-link
    (if (looking-back "^[ \t]+" (line-beginning-position))
        (delete-region (match-beginning 0) (match-end 0))
      (newline))
    (cond ((image-type-from-file-name filename)
           (insert
            (concat
             (if (= org-download-image-html-width 0) ""
               (format "#+attr_html: :width %dpx\n" org-download-image-html-width))
             (if (= org-download-image-latex-width 0) ""
               (format "#+attr_latex: :width %dcm\n" org-download-image-latex-width))
             (if (= org-download-image-org-width 0) ""
               (format "#+attr_org: :width %dpx\n" org-download-image-org-width))
             (format org-download-link-format
                     (if (file-in-directory-p filename org-attach-id-dir)
                         (file-relative-name filename org-attach-id-dir)
                       filename))))
           (org-display-inline-images))
          ((insert
            (format "%s [[./%s][%s]] "
                    (+org-attach-icon-for filename)
                    (file-relative-name filename (file-name-directory buffer-file-name))
                    (file-name-nondirectory (directory-file-name filename)))))))

  (advice-add #'org-download--dir-2 :override #'ignore)
  (defadvice! +org--dragndrop-download-fullname-a (path)
    "Write PATH relative to current file."
    :filter-return #'org-download--fullname
    (let ((dir (or (if buffer-file-name (file-name-directory buffer-file-name))
                   default-directory)))
      (if (file-in-directory-p dir org-attach-id-dir)
          (file-relative-name path dir)
        path))))
