;; -*- no-byte-compile: t; -*-
;;; ui/modeline/packages.el

(unless (featurep! +light)
  (package! doom-modeline :pin "fb34eb5eb60f41ce1bc23c2bad6ac20de5669f22"))
(package! anzu :pin "b3d15fba5590286209424b8c2d6765265076f034")
(when (featurep! :editor evil)
  (package! evil-anzu :pin "d3f6ed4773b48767bd5f4708c7f083336a8a8a86"))
