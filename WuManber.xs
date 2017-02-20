/*
 * WuManber.xs
 * Copyright (c) 2007-2010, Juergen Weigert, Novell Inc.
 * This module is free software. It may be used, redistributed
 * and/or modified under the same terms as Perl itself.
 *
 * see perldoc perlxstut
 * see Rolf Stiebe; Textalgoritmen WS 2005/6
 * see TR94-17_WuManber.pdf
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "wumanber_impl.h"


static void push_result(unsigned int idx, unsigned long offset, void *data)
{
  AV *r = (AV *)data;

  // In perl, indices run from 0..n_pat-1
  // In C, indices run from 1..n_pat

#if 1
  AV *loc = (AV *)sv_2mortal((SV *)newAV());
  av_push(loc, newSVnv(offset));
  av_push(loc, newSVnv(idx-1));
  av_push(r, newRV((SV *)loc));
#else
  av_push(r, newSVnv(offset));
  av_push(r, newSVnv(idx-1));
#endif
}

typedef struct WuManber * Search__WuManber__Obj;

MODULE = Search::WuManber	PACKAGE = Search::WuManber
PROTOTYPES: ENABLE

Search::WuManber::Obj
init_tables(p, case_sensitive)
    AV* p;
    unsigned int case_sensitive;
  PREINIT:
    SV** pp;
    SV **svp;
    int i, n_patterns;
    unsigned char **pattern_list;
    struct WuManber *wm;
  CODE:
    Newxz (wm, 1, struct WuManber);
    wm->mallocs++;
    wm->progname = "perl(Search::WuManber)";
    i = 0;
    n_patterns = av_len(p) + 1;
    Newxz (pattern_list, n_patterns+1, unsigned char *);
    wm->mallocs++;
    while (i++ < n_patterns)
      {
        SV** ep = av_fetch(p, i-1, 0);
	STRLEN slen;
	unsigned char *e;

	// next test not really needed. perl converts almost anything to string.
	if (!SvPOK(*ep)) croak("init_tables: pattern[%d] is not a string\n", i);
	pattern_list[i] = e = (unsigned char *)SvPV(*ep, slen);

        // printf("pattern[%d] = '%s'\n", i, e);
      }
    pattern_list[i] = NULL;	// just to be sure

    prep_pat(wm, n_patterns, pattern_list, !case_sensitive);

    RETVAL = wm;

  OUTPUT:
    RETVAL


SV *
find_all(wm,textsv)
    Search::WuManber::Obj wm
    SV *textsv

  PREINIT:
    AV *r;	// return value
    STRLEN text_len, n;
    unsigned char *text;
    SV **svp;

    text = (unsigned char *)SvPV(textsv, text_len);
    // warn("find_all: text='%s', text_len=%d\n", text, (unsigned int)text_len);

  INIT:
    search_init(wm, "argv[0]");

    r = (AV *)sv_2mortal((SV *)newAV());
    wm->cb = push_result;
    wm->cb_data = (void *)r;

  CODE:
    search_text(wm, text, text_len);
    RETVAL = newRV((SV *)r);
  OUTPUT:
    RETVAL

MODULE = Search::WuManber	PACKAGE = Search::WuManber::Obj

void
DESTROY(wm)
	Search::WuManber::Obj wm
CODE:
	//printf ("Destroying %p\n", wm);
	WuManber_free (wm);
	Safefree (wm->patt);
	wm->mallocs--;
	if (wm->mallocs != 1) {
	    fprintf (stderr, "%s:%d: wm->mallocs = %d, should be 1.\n",
		     __FILE__, __LINE__, wm->mallocs);
	}
	Safefree (wm);

