/*****************************************************************************

 @(#) $RCSfile$ $Name$($Revision$) $Date$

 -----------------------------------------------------------------------------

 Copyright (c) 2001-2007  OpenSS7 Corporation <http://www.openss7.com/>
 Copyright (c) 1997-2000  Brian F. G. Bidulock <bidulock@openss7.org>

 All Rights Reserved.

 This program is free software: you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation, version 3 of the license.

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 details.

 You should have received a copy of the GNU General Public License along with
 this program.  If not, see <http://www.gnu.org/licenses/>, or write to the
 Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 -----------------------------------------------------------------------------

 U.S. GOVERNMENT RESTRICTED RIGHTS.  If you are licensing this Software on
 behalf of the U.S. Government ("Government"), the following provisions apply
 to you.  If the Software is supplied by the Department of Defense ("DoD"), it
 is classified as "Commercial Computer Software" under paragraph 252.227-7014
 of the DoD Supplement to the Federal Acquisition Regulations ("DFARS") (or any
 successor regulations) and the Government is acquiring only the license rights
 granted herein (the license rights customarily provided to non-Government
 users).  If the Software is supplied to any unit or agency of the Government
 other than DoD, it is classified as "Restricted Computer Software" and the
 Government's rights in the Software are defined in paragraph 52.227-19 of the
 Federal Acquisition Regulations ("FAR") (or any successor regulations) or, in
 the cases of NASA, in paragraph 18.52.227-86 of the NASA Supplement to the FAR
 (or any successor regulations).

 -----------------------------------------------------------------------------

 Commercial licensing and support of this software is available from OpenSS7
 Corporation at a fee.  See http://www.openss7.com/

 -----------------------------------------------------------------------------

 Last Modified $Date$ by $Author$

 -----------------------------------------------------------------------------

 $Log$
 *****************************************************************************/

#ident "@(#) $RCSfile$ $Name$($Revision$) $Date$"

static char const ident[] = "$RCSfile$ $Name$($Revision$) $Date$";

/* rywait.c - ROSY: wait */

#ifndef	lint
static char *rcsid =
    "Header: /xtel/isode/isode/rosy/RCS/rywait.c,v 9.0 1992/06/16 12:37:29 isode Rel";
#endif

/* 
 * Header: /xtel/isode/isode/rosy/RCS/rywait.c,v 9.0 1992/06/16 12:37:29 isode Rel
 *
 *
 * Log: rywait.c,v
 * Revision 9.0  1992/06/16  12:37:29  isode
 * Release 8.0
 *
 */

/*
 *				  NOTICE
 *
 *    Acquisition, use, and distribution of this module and related
 *    materials are subject to the restrictions of a license agreement.
 *    Consult the Preface in the User's Manual for the full terms of
 *    this agreement.
 *
 */

/* LINTLIBRARY */

#include <stdio.h>
#include "rosy.h"

#ifdef __STDC__
#define missingP(p) \
{ \
    if (p == NULL) \
        return rosaplose (roi, ROS_PARAMETER, NULLCP, \
                            "mandatory parameter \"%s\" missing", #p); \
}
#else
#define	missingP(p) \
{ \
    if (p == NULL) \
	return rosaplose (roi, ROS_PARAMETER, NULLCP, \
			    "mandatory parameter \"%s\" missing", "p"); \
}
#endif

/*    WAIT */

int
RyWait(sd, id, out, secs, roi)
	int sd, *id, secs;
	caddr_t *out;
	struct RoSAPindication *roi;
{
	int reason, result;
	register struct opsblk *opb;

#ifdef	notdef
	missingP(out);
#endif
	missingP(roi);

	if (id) {
		if ((opb = findopblk(sd, *id, OPB_INITIATOR)) == NULLOPB)
			return rosaplose(roi, ROS_PARAMETER, NULLCP,
					 "invocation %d not in progress on association %d",
					 *id, sd);
	} else
		opb = firstopblk(sd);

	if (out && opb && (opb->opb_flags & OPB_EVENT)) {
		*out = opb->opb_out;
		*roi = opb->opb_event;	/* struct copy */
		opb->opb_out = NULL;
		freeopblk(opb);

		return OK;
	}

	if (!id)
		opb = NULLOPB;

	switch (result = RoWaitRequest(sd, secs, roi)) {
	case NOTOK:
		reason = roi->roi_preject.rop_reason;
		if (ROS_FATAL(reason))
			loseopblk(sd, reason);
		break;

	case DONE:
		loseopblk(sd, ROS_IP_RELEASE);
		break;

	case OK:
		result = RyWaitAux(sd, opb, out, secs, roi);
		break;

	default:
		result = rosaplose(roi, ROS_PROTOCOL, NULLCP,
				   "unknown return from RoWaitRequest=%d", result);
		break;
	}

	return result;
}

/*  */

int
RyWaitAux(sd, opb, out, secs, roi)
	int sd;
	register struct opsblk *opb;
	int secs;
	caddr_t *out;
	struct RoSAPindication *roi;
{
	int id, reason, result;
	char *cp;
	caddr_t in;
	register struct dspblk *dsb;
	register struct opsblk *op2;
	register struct RyError **rye;
	register struct RyOperation *ryo;

	missingP(roi);

	if (out)
		*out = NULL;

	for (;;) {
		switch (roi->roi_type) {
		case ROI_INVOKE:{
			struct RoSAPinvoke roxs;
			register struct RoSAPinvoke *rox = &roxs;

			*rox = roi->roi_invoke;	/* struct copy */

			if (op2 = findopblk(sd, rox->rox_id, OPB_RESPONDER)) {
				(void) rosaplose(roi, result = ROS_IP_DUP, NULLCP,
						 "duplicate invocation %d", rox->rox_id);

			      bad_request:;
				(void) RoURejectRequest(sd, &rox->rox_id, result, ROS_NOPRIO, roi);
				ROXFREE(rox);

				if (opb == NULLOPB)
					return NOTOK;
				goto next;
			}

			if ((dsb = finddsblk(sd, rox->rox_op)) == NULLDSB
			    && (dsb = finddsblk(NOTOK, rox->rox_op))
			    == NULLDSB) {
				(void) rosaplose(roi, result = ROS_IP_UNRECOG, NULLCP,
						 "unexpected invocation %d of operation %d",
						 rox->rox_id, rox->rox_op);
				goto bad_request;
			}

			ryo = dsb->dsb_ryo;
			in = NULL;
			if (rox->rox_args) {
#ifdef PEPSY_DEFINITIONS
				if (!ryo->ryo_arg_mod) {	/* XXX: MISTYPED? */
#else
				if (!ryo->ryo_arg_decode) {	/* XXX: MISTYPED? */
#endif
					(void) rosaplose(roi, result = ROS_IP_MISTYPED,
							 NULLCP,
							 "unexpected argument for invocation %d of operation %s/%d",
							 rox->rox_id, ryo->ryo_name, ryo->ryo_op);
					goto bad_request;
				}

				PY_pepy[0] = 0;
#ifdef PEPSY_DEFINITIONS
				if (dec_f(ryo->ryo_arg_index, ryo->ryo_arg_mod,
					  rox->rox_args, 1, NULLIP, NULLVP, &in)
				    == NOTOK) {
#else
				if ((*ryo->ryo_arg_decode) (rox->rox_args, 1, NULLIP,
							    NULLVP, &in) == NOTOK) {
#endif
					(void) rosaplose(roi, result = ROS_IP_MISTYPED,
							 NULLCP,
							 "mistyped argument for invocation %d of operation %s/%d [%s]",
							 rox->rox_id, ryo->ryo_name, ryo->ryo_op,
							 PY_pepy);
					goto bad_request;
				}
			}

			if (ryo->ryo_result || ryo->ryo_errors) {
				if ((op2 = newopblk(sd, rox->rox_id)) == NULLOPB) {
					(void) rosaplose(roi, result = ROS_IP_LIMIT, NULLCP,
							 "unable to allocate opblock for invocation %d of operation %s/%d",
							 rox->rox_id, ryo->ryo_name, ryo->ryo_op);
					goto bad_request;
				}
				op2->opb_flags &= ~OPB_INITIATOR;
				op2->opb_flags |= OPB_RESPONDER;
				op2->opb_ryo = ryo;
			}

			result = (*dsb->dsb_vector) (sd, ryo, rox, in, roi);
#ifdef PEPSY_DEFINITIONS
			if (in && ryo->ryo_arg_mod)
				(void) fre_obj(in,
					       ryo->ryo_arg_mod->md_dtab[ryo->ryo_arg_index],
					       ryo->ryo_arg_mod, 1);
#else
			if (in && ryo->ryo_arg_free)
				(void) (*ryo->ryo_arg_free) (in);
#endif
			ROXFREE(rox);

			switch (result) {
			default:
				result = rosaplose(roi, ROS_PROTOCOL, NULLCP,
						   "%s invoke dispatch for invoke id %d returns %d",
						   ryo->ryo_name, rox->rox_id, result);
				/* and fall */
			case NOTOK:
				if (opb != NULLOPB)
					break;
			case DONE:
				return result;

			case OK:
				break;
			}
			goto next;
		}

		case ROI_RESULT:{
			register struct RoSAPresult *ror = &roi->roi_result;

			if ((op2 = findopblk(sd, ror->ror_id, OPB_INITIATOR))
			    == NULLOPB || (op2->opb_flags & OPB_EVENT)) {
				(void) RoURejectRequest(sd, &ror->ror_id,
							ROS_RRP_UNRECOG, ROS_NOPRIO, roi);
				RORFREE(ror);
				goto next;
			}

			ryo = op2->opb_ryo;
			if (!ryo->ryo_result) {
				result = ROS_RRP_UNEXP;

			      bad_result:;
				RORFREE(ror);
				goto bad_response;
			}
#ifdef PEPSY_DEFINITIONS
			if (ryo->ryo_res_mod) {	/* XXX: MISTYPED? */
#else
			if (ryo->ryo_res_decode) {	/* XXX: MISTYPED? */
#endif
				if (!ror->ror_result) {
					result = ROS_RRP_MISTYPED;
					goto bad_result;
				}
				PY_pepy[0] = 0;
#ifdef PEPSY_DEFINITIONS
				result = dec_f(ryo->ryo_res_index,
					       ryo->ryo_res_mod, ror->ror_result,
					       1, NULLIP, NULLVP, &op2->opb_out);
				op2->opb_free_index = ryo->ryo_res_index;
				op2->opb_free_mod = ryo->ryo_res_mod;
#else
				result = (*ryo->ryo_res_decode) (ror->ror_result, 1,
								 NULLIP, NULLVP, &op2->opb_out);
				op2->opb_free = ryo->ryo_res_free;
#endif
			} else {
				if (ror->ror_result) {
					result = ROS_RRP_MISTYPED;
					goto bad_result;
				}

				result = OK;
			}

			op2->opb_pe = ror->ror_result, ror->ror_result = NULLPE;
			RORFREE(ror);

			if (result == NOTOK) {
				result = ROS_RRP_MISTYPED;
				goto bad_response;
			}

			if (op2->opb_resfnx) {
				result = (*op2->opb_resfnx) (sd, op2->opb_id,
							     RY_RESULT, op2->opb_out, roi);
				freeopblk(op2);

				id = ror->ror_id, cp = "result";
			      punch:;
				switch (result) {
				default:
					result = rosaplose(roi, ROS_PROTOCOL, NULLCP,
							   "%s %s dispatch for invoke id %d returns %d",
							   ryo->ryo_name, cp, id, result);
					/* and fall */
				case NOTOK:
					if (opb != NULLOPB)
						break;
				case DONE:
					return result;

				case OK:
					break;
				}
				if (opb == op2)
					return OK;
				goto next;
			}

			if (opb == NULLOPB || opb == op2) {
				if (out == NULL) {
				      waiting:;
					op2->opb_flags |= OPB_EVENT;
					op2->opb_event = *roi;	/* struct copy */
					return rosaplose(roi, ROS_WAITING, NULLCP, NULLCP);
				}

				*out = op2->opb_out;
				op2->opb_out = NULL;
				freeopblk(op2);

				return OK;
			}

			op2->opb_flags |= OPB_EVENT;
			op2->opb_event = *roi;	/* struct copy */
			goto next;
		}

		case ROI_ERROR:{
			register struct RoSAPerror *roe = &roi->roi_error;

			if ((op2 = findopblk(sd, roe->roe_id, OPB_INITIATOR))
			    == NULLOPB || (op2->opb_flags & OPB_EVENT)) {
				(void) RoURejectRequest(sd, &roe->roe_id,
							ROS_REP_UNRECOG, ROS_NOPRIO, roi);
				ROEFREE(roe);
				goto next;
			}

			ryo = op2->opb_ryo;
			if (!(rye = ryo->ryo_errors)) {
				result = ROS_REP_UNEXP;

			      bad_error:;
				ROEFREE(roe);
				goto bad_response;
			}
			for (; *rye; rye++)
				if ((*rye)->rye_err == roe->roe_error)
					break;
			if (!*rye) {
				result = ROS_REP_UNEXPERR;
				goto bad_error;
			}
#ifdef PEPSY_DEFINITIONS
			if ((*rye)->rye_param_mod) {	/* XXX: MISTYPED? */
#else
			if ((*rye)->rye_param_decode) {	/* XXX: MISTYPED? */
#endif
				if (!roe->roe_param) {
					result = ROS_REP_MISTYPED;
					goto bad_error;
				}
#ifdef PEPSY_DEFINITIONS
				result = dec_f((*rye)->rye_param_index,
					       (*rye)->rye_param_mod, roe->roe_param,
#else
				result = (*(*rye)->rye_param_decode) (roe->roe_param,
#endif
								      1, NULLIP, NULLVP,
								      &op2->opb_out);
#ifdef PEPSY_DEFINITIONS
				op2->opb_free_index = (*rye)->rye_param_index;
				op2->opb_free_mod = (*rye)->rye_param_mod;
#else
				op2->opb_free = (*rye)->rye_param_free;
#endif
			} else {
				if (roe->roe_param) {
					result = ROS_REP_MISTYPED;
					goto bad_error;
				}

				result = OK;
			}

			op2->opb_pe = roe->roe_param, roe->roe_param = NULLPE;
			ROEFREE(roe);

			if (result == NOTOK) {
				result = ROS_REP_MISTYPED;
				goto bad_response;
			}

			if (op2->opb_errfnx) {
				result = (*op2->opb_errfnx) (sd, op2->opb_id,
							     roe->roe_error, op2->opb_out, roi);
				freeopblk(op2);

				id = roe->roe_id, cp = "error";
				goto punch;
			}

			if (opb == NULLOPB || opb == op2) {
				if (out == NULL)
					goto waiting;
				*out = op2->opb_out;
				op2->opb_out = NULL;
				freeopblk(op2);

				return OK;
			}

			op2->opb_flags |= OPB_EVENT;
			op2->opb_event = *roi;	/* struct copy */
			goto next;
		}

		case ROI_UREJECT:{
			register struct RoSAPureject *rou = &roi->roi_ureject;

			if (rou->rou_noid)
				op2 = opb;
			else if ((op2 = findopblk(sd, rou->rou_id, OPB_INITIATOR))
				 == NULLOPB || (op2->opb_flags & OPB_EVENT))
				goto next;

			if (op2->opb_errfnx) {
				result = (*op2->opb_errfnx) (sd, id = op2->opb_id,
							     RY_REJECT,
							     (caddr_t) rou->rou_reason, roi);
				freeopblk(op2);

				cp = "reject";
				goto punch;
			}

			if (opb == NULLOPB || opb == op2) {
				freeopblk(op2);

				return OK;
			}

			op2->opb_flags |= OPB_EVENT;
			op2->opb_event = *roi;	/* struct copy */
			goto next;
		}

		default:
			return rosaplose(roi, ROS_PROTOCOL, NULLCP,
					 "unknown indication type=%d", roi->roi_type);
		}

	      bad_response:;
		{
			register struct RoSAPureject *rou = &roi->roi_ureject;

			(void) RoURejectRequest(op2->opb_fd, &op2->opb_id, result, ROS_NOPRIO, roi);

			roi->roi_type = ROI_UREJECT;
			rou->rou_id = op2->opb_id;
			rou->rou_noid = 0;
			rou->rou_reason = result;

			if (op2->opb_errfnx) {
				result = (*op2->opb_errfnx) (sd, id = op2->opb_id, RY_REJECT,
							     (caddr_t) rou->rou_reason, roi);

				freeopblk(op2);

				cp = "reject";
				goto punch;
			}

			if (opb == NULLOPB || opb == op2) {
				freeopblk(op2);

				return OK;
			}

			op2->opb_flags |= OPB_EVENT;
			op2->opb_event = *roi;	/* struct copy */
		}
		/* and fall... */

	      next:;
		if (secs != NOTOK)
			return rosaplose(roi, ROS_TIMER, NULLCP, NULLCP);

		switch (result = RoWaitRequest(sd, NOTOK, roi)) {
		case NOTOK:
			reason = roi->roi_preject.rop_reason;
			if (ROS_FATAL(reason))
				loseopblk(sd, reason);
			break;

		case DONE:
			loseopblk(sd, ROS_IP_RELEASE);
			break;

		case OK:
			continue;

		default:
			result = rosaplose(roi, ROS_PROTOCOL, NULLCP,
					   "unknown return from RoWaitRequest=%d", result);
			break;
		}

		return result;
	}
}