/*
 * MediaServiceListener.java Version-1.4, 2002/11/22 09:26:10 -0800 (Fri)
 * ECTF S.410-R2 Source code distribution.
 *
 * Copyright (c) 2002, Enterprise Computer Telephony Forum (ECTF),
 * All Rights Reserved.
 *
 * Use and redistribution of this file is subject to a License.
 * For terms and conditions see: javax/telephony/media/LICENSE.HTML
 * 
 * In short, you can use this source code if you keep and display
 * the ECTF Copyright and the License conditions. The code is supplied
 * "AS IS" and ECTF disclaims all warranties and liability.
 */

package javax.telephony.media;

import javax.telephony.*;		// for javadoc to find Connection

/**
 * Listener for non-transactional events generated by a MediaService.
 *
 * @author  Jeff Peck
 * @since   JTAPI-1.3
 */
public 
interface MediaServiceListener extends MediaListener, MediaServiceConstants {
    /**
     * A [JTAPI] Connection to the MediaService has been disconnected.
     * This method is invoked when
     * the Connection to the bound Terminal transitions to the state
     * <code>{@link Connection#DISCONNECTED}</code>.
     * <p>
     * <b>Related processing:</b><p>
     * If <tt>event.getEventID().equals(ev_Disconnected</tt>, 
     * and <tt>(a_StopOnDisconnect == TRUE)</tt> then
     * all resource transactions have been terminated.
     * <p>
     * If <tt>event.getEventID().equals(ev_TerminalIdle)</tt>, 
     * then there are no more Connections to the Terminal,
     * and all resource transactions have been terminated.
     * <p>
     * Corresponds to <tt>CCR_ECTF_State = CCR_ECTF_Idle</tt>, in S.100. ?
     *
     * @param event a MediaServiceEvent with EventID:
     * <tt>ev_Disconnected</tt> or <tt>ev_TerminalIdle</tt>
     */
    void onDisconnected(MediaServiceEvent event);

    /** 
     * Invoked when the [JTAPI] Connection to a MediaService is <tt>CONNECTED</tt>.
     * Corresponds to <tt>CCR_ECTF_State = CCR_ECTF_Active</tt>, in S.100.
     * <p>
     * The Connection to the MediaService is now <tt>CONNECTED</tt>,
     * the media stream is active and available.
     *
     * @since 1.4
     *
     * @param event a MediaServiceEvent with EventID: 
     * <tt>ev_Connected</tt>
     */
    void onConnected(MediaServiceEvent event); 

    /**
     * A previous owner has retrieved the MediaGroup of this MediaService.
     * This MediaService is now unbound.
     * <p>
     * <tt>event.getEventID().equals(ev_Retrieved)</tt>
     * <br>
     * <tt>event.getQualifier().equals(retrieval cause Symbol)</tt>
     * <p>
     * <b>Note:</b> <tt>onRetrieved()</tt> may be invoked even 
     * if <i>this</i> application is not using delegation! 
     * Any application that uses <tt>bindToServiceName()</tt>
     * may receive a MediaGroup from an application
     * that will later decide to retrieve it.
     * <p>
     * <b>Note:</b>
     * if the MediaGroup is retrieved while this MediaService has
     * <i>delegated</i> the MediaGroup, then <tt>delegateToService</tt>
     * will complete with <tt>getQualifier().equals(ev_Retrieved)</tt>
     * and the cause Symbol is available using <tt>event.getRetrieveCause()</tt>.
     * <p>
     * <b>Note:</b>
     * <i>parameter is a simple MediaServiceEvent!<br>
     * The only relevant info is the <tt>retrieveCause;</tt>
     * and that goes in the qualifier.</i>
     * <p>
     * @since 1.4
     * @param event a MediaServiceEvent with EventID: 
     * <tt>ev_Retrieved</tt>
     *
     * @see Delegation#retrieve
     */
    void onRetrieved(MediaServiceEvent event);
}