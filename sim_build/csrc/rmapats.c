// file = 0; split type = patterns; threshold = 100000; total count = 0.
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

void  schedNewEvent (struct dummyq_struct * I1443, EBLK  * I1438, U  I628);
void  schedNewEvent (struct dummyq_struct * I1443, EBLK  * I1438, U  I628)
{
    U  I1725;
    U  I1726;
    U  I1727;
    struct futq * I1728;
    struct dummyq_struct * pQ = I1443;
    I1725 = ((U )vcs_clocks) + I628;
    I1727 = I1725 & ((1 << fHashTableSize) - 1);
    I1438->I674 = (EBLK  *)(-1);
    I1438->I675 = I1725;
    if (0 && rmaProfEvtProp) {
        vcs_simpSetEBlkEvtID(I1438);
    }
    if (I1725 < (U )vcs_clocks) {
        I1726 = ((U  *)&vcs_clocks)[1];
        sched_millenium(pQ, I1438, I1726 + 1, I1725);
    }
    else if ((peblkFutQ1Head != ((void *)0)) && (I628 == 1)) {
        I1438->I677 = (struct eblk *)peblkFutQ1Tail;
        peblkFutQ1Tail->I674 = I1438;
        peblkFutQ1Tail = I1438;
    }
    else if ((I1728 = pQ->I1344[I1727].I697)) {
        I1438->I677 = (struct eblk *)I1728->I695;
        I1728->I695->I674 = (RP )I1438;
        I1728->I695 = (RmaEblk  *)I1438;
    }
    else {
        sched_hsopt(pQ, I1438, I1725);
    }
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
