;; This code creates ruby code to replace special symbols with the corresponding utf8/html code

(require 'org-entities)

(defvar gen-use-entities-user t)
(defvar gen-file-name "replace-entities.rb")

(defun generate-replace-inbuffer (what)
  (let ((ll (if gen-use-entities-user
                (append org-entities-user org-entities)
              org-entities))
        (to (if (string= what "html") 3
              6))) ; use utf8 for textile
    (insert "  " (capitalize what) "Entities = {")
    (dolist (entity ll)
      (when (listp entity)
        (let ((symb (nth to entity)))
          ;; escape backslashes and quotation marks
          (setq symb (replace-regexp-in-string "\\(\\\\\\|\\\"\\)" "\\\\\\&" symb))
          (insert "\n    \"" (car entity) "\" => \"" symb "\","))))
    ;; remove last comma from the sequence
    (search-backward ",")
    (replace-match "")
    (insert "\n  }\n")))

(defun generate-replace-header (what)
  (insert
   "# Autogenerated by util/gen-special-replace.el\n\n"
   "module Orgmode\n"))

(defun generate-replace-footer (what)
  (insert
   "  @org_entities_regexp = /\\\\(there4|sup[123]|frac[13][24]|[a-zA-Z]+)($|\\{\\}|[^a-zA-Z])/\n\n"
   "  def Orgmode.special_symbols_to_" what " str\n"
   "    str.gsub! @org_entities_regexp do |match|\n"
   "      if " (capitalize what) "Entities[$1]\n"
   "        if $2 == \"{}\" then \"#{" (capitalize what) "Entities[$1]}\"\n"
   "        else \"#{" (capitalize what) "Entities[$1]}#{$2}\"\n"
   "        end\n"
   "      end\n"
   "    end\n"
   "  end\n"
   "end # module Orgmode\n"))

(defun generate-replace (file-name what)
  (let ((file (expand-file-name file-name)))
    (with-temp-buffer
      (generate-replace-header what)
      (generate-replace-inbuffer what)
      (generate-replace-footer what)
      (write-file file))))

(generate-replace "../lib/org-ruby/html_symbol_replace.rb" "html")
(generate-replace "../lib/org-ruby/textile_symbol_replace.rb" "textile")
