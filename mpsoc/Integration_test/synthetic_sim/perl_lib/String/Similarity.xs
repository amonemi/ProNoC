#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
 
#include "fstrcmp.h"
#include "fstrcmp.c"
 
UV *
text2UV (SV *sv, STRLEN *lenp)
{
  STRLEN len;
  char *s = SvPV (sv, len);
  UV *r = (UV *)SvPVX (sv_2mortal (NEWSV (0, (len + 1) * sizeof (UV))));
  UV *p = r;
 
  if (SvUTF8 (sv))
    {
       STRLEN clen;
       while (len)
         {
           *p++ = utf8n_to_uvchr (s, len, &clen, 0);
 
           if (clen < 0)
             croak ("illegal unicode character in string");
 
           s += clen;
           len -= clen;
         }
    }
  else
    while (len--)
      *p++ = *(unsigned char *)s++;
 
  *lenp = p - r;
  return r;
}
 
MODULE = String::Similarity             PACKAGE = String::Similarity
 
double
fstrcmp(s1, s2, minimum_similarity = 0)
        SV *    s1
        SV *    s2
        double  minimum_similarity
        PROTOTYPE: @
        CODE:
{
        STRLEN l1, l2;
        UV *c1 = text2UV (s1, &l1);
        UV *c2 = text2UV (s2, &l2);
        RETVAL = fstrcmp (c1, l1, c2, l2, minimum_similarity);
}
        OUTPUT:
        RETVAL
