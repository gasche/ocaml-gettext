(** Signature of module for domain management *)

open GettextUtils;;

module type DOMAIN_TYPE = 
  functor ( Locale : GettextLocale.LOCALE_TYPE ) ->
  sig
    type textdomain    = string
    type dir           = string
    type category      = Locale.category
    
    type t

    (** create language locale : create a new binding for textdomain
        considering. Language is guessed from locale environnement.
    *)
    val create : Locale.t -> t

    (** add textdomain dir t : add the binding of textdomain to dir.
    *)
    val add : textdomain -> dir -> t -> t 

    (** compute_path textdomain category t : return the path to the 
        mo file corresponding to textdomain and category. Language is 
        guessed from category binding. If the textdomain is not found,
        it tries to use the build default to find the file. The file 
        returned exists and is readable. If the file is not readable, 
        an exception GettextDomainFileUnreadable is thrown, if file 
        doesn't exists an exception GettextDomainFileDoesntExist is 
        thrown.
    *)
    val compute_path : textdomain -> category -> t -> dir
  end
;;

module Generic : DOMAIN_TYPE = 
  functor ( Locale : GettextLocale.LOCALE_TYPE ) ->
  struct    
    type textdomain  = string
    type dir         = string
    type category    = Locale.category

    type t = {
      locale : Locale.t;
      map    : dir MapString.t;
    }

    let create locale = {
      locale = locale;
      map    = MapString.empty;
    }

    let add textdomain dir domain = {
      locale = domain.locale;
      map    = MapString.add textdomain dir 
    }

    let compute_path textdomain category domain = 
      let search_path = 
        try 
          MaptString.find textdomain domain.map :: GettextConfig.default_paths
        with Not_found ->
          GettextConfig.default_paths
      in
      (* http://www.gnu.org/software/gettext/manual/html_mono/gettext.html#SEC148 
        dir_name/locale/LC_category/domain_name.mo *)
      let end_path = 
        (* BUG : that default language should be guessed using
           LANGUAGE/LC_CTYPE... *)
        make_filename [ 
          Locale.get_locale category;
          Locale.string_of_category category ; 
          (* BUG : should use add_extension *)
          domain ^ ".mo" 
        ]
      in
      let compute_simple_path dir = 
        concat dir end_path
      in
      List.find (test (And(Exists,Is_readable))
      (List.map compute_simple_path search_path)
          
  end
;;
