using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Xml;
using System.Configuration;

using DevExpress.Web;

using eCAR3Lib;
using eCAR3Lib.Helpers;
using eCAR3Lib.Models;
using log4net;

namespace eCAR3Web
{
    public partial class WFMainMaster2 : System.Web.UI.MasterPage, PageData
    {
        public WFMainMaster2()
        {

        }

        // This function is duplicated - but it's only one line...
        public WFEngine GetWFEngine()
        {
            return Master.GetWFEngine();
        }

        public MailHelper GetMailHelper()
        {
            return Master.GetMailHelper();
        }

        public void HideSummaryPanel()
        {
            //carSummary.Visible = false;
            //CommentsCtrl.Visible = false;
        }

        protected void Page_Init(object sender, EventArgs e)
        {
            // Give the page a chance to find its assignment
            if (Assignment == null && Page is WFPageBase)
            {
                Assignment = ((WFPageBase)Page).FindAssignment();
            }

            if (Assignment == null) //If the User is NOT ASSIGNED
            {
                // Hide workflow bar and leave - there's nothing we can do!
                layoutWorkflowButtons.Visible = true;

                // This effectively only shows the save button
                btnWF0.Visible = false;
                btnWF1.Visible = false;
                btnWF2.Visible = false;
                btnWF3.Visible = false;
                btnWF4.Visible = false;
                btnSave.ClientVisible = false;             //default Save button
                btnPrint.ClientVisible = true;             //default Print button
                btnAddComments.ClientVisible = false;      //default Comments button
                btnPrintPowerPoint.ClientVisible = false;  //default PrintPowerPoint button
            }
        }

        public void SetReadOnly(bool PbReadOnly = true)
        {
            //Comments.ReadOnly = PbReadOnly;
        }

        public void btnWFComments_Click(object sender, EventArgs e)
        {
            // This saves the comments...
            String sAction = WFCommentsWindow.HeaderText;

            string startUpScript = string.Format("CommentsComplete('{0}');", sAction);
            Page.ClientScript.RegisterStartupScript(this.GetType(), "ANY_KEY", startUpScript, true);

        }

        // This fixes up the buttons
        // I'm not sure where the Session comes from
        protected void Page_Load(object sender, EventArgs e)
        {
            //Set CARId to hidden field
            hfCARId.Value = CAR.CARId.ToString();

            // Prevent spoofing
            if (Assignment != null && Assignment.UserId != Master.UserId)
            {
                // You appear to have spoofed the page
                Response.Redirect("~/Unauthorized.aspx");
                return;
            }

            // Nothing further to do with no assignment
            if (Assignment == null)
            {
                //Does user have super user or admin role?
                if (User.HasRole(Role.ADMIN) || User.HasRole(Role.SUPER))
                {
                    //Enable Comments button
                    btnAddComments.ClientVisible = true;
                }

 

                if (User.HasRole(Role.SUPER) || User.UserName == "Anderson, Howard")  //#PFG-KLUDGE
                {
                    btnPrintPowerPoint.ClientVisible = true;    //Enable PowerPoint Print button
                    btnSave.ClientVisible = true;               //Enable Save button
                }

                return;
            }

            // Be sure that this item is still assigned to you
            if (Assignment.CurStatus != "Assigned")
            {
                string sDoneParam = Request["done"];
                if (sDoneParam == null || sDoneParam != "1")
                {
                    Response.Redirect("~/InvalidWorkItem.aspx");
                    return;
                }
            }

            int i = 0;
            List<ASPxButton> lsButtons = new List<ASPxButton>
            {
                btnWF0,
                btnWF1,
                btnWF2,
                btnWF3,
                btnWF4
            };


            foreach (ASPxButton pButton in lsButtons)
            {
                pButton.Visible = false;
            }

            if (Assignment.CurStatus == "Assigned")
            {
                // Do not enable workflow buttons if the item is already done
                btnAddComments.ClientVisible = true;        //Enable Comments button

                //Does user not have super user role?
                if (User.HasRole(Role.SUPER) || User.UserName == "Anderson, Howard")  //#PFG-KLUDGE
                {
                    btnPrintPowerPoint.ClientVisible = false;    //Disable PowerPoint Print button
                }


                // Adjust buttons on the fly
                WFEngine pEngine = GetWFEngine();

                ActionInfo[] aActions = pEngine.GetActions(Assignment.StepName, Assignment.RoleId);
                foreach (ActionInfo pAction in aActions)
                {
                    ASPxButton pButton = lsButtons[i];
                    pButton.Text = pAction.Action;
                    pButton.ToolTip = pAction.Tooltip;
                    if (pAction.RequireComments)
                        pButton.ClientSideEvents.Click = "onWFComments";
                    else
                        pButton.ClientSideEvents.Click = "onWFButtonClick";

                    pButton.Visible = true;
                    i++;
                }
            }

            if (!IsPostBack)
            {
                // Use assignment ID to find the row
                // This is now uniform - the checklists do it too
                CARComment pRow = PageContext.CARComments.FirstOrDefault(x => x.WFAssignId == Assignment.WFAssignId);
                if (pRow != null)
                {
                    //if (pRow.Comments != null) {
                    //  Comments.Text = pRow.Comments;
                    //}
                }
            }

            // This should make it so that approvers can add attachments, and collaborators cannot // 3-25-19 Todd changed this so that both Approver and Collaborator can add attachments. Joey requested this change.
            if (Assignment.RoleCategory == "Approver" || Assignment.RoleCategory == "Collaborator")
            {
                //carSummary.UploadEnabled = true;
            }

            //layoutComments.Items [0].Caption = Assignment.Role.RoleName;
        }

        protected void dsCurComment_Selecting(object sender, Microsoft.AspNet.EntityDataSource.EntityDataSourceSelectingEventArgs e)
        {
            if (Assignment != null)
                e.DataSource.Where = String.Format("it.WFAssignId = {0}", Assignment.WFAssignId);
        }

        // Save controls - this prevents a full page callback
        protected void cbMasterSave_Callback(object source, CallbackEventArgs e)
        {
            // We'll always save...
            // Save ths page content
            // This starts the entire cascade of save events
            if (MainContent.Page is WFPageBase)
            {
                WFPageBase pPage = (WFPageBase)MainContent.Page;

                // Save the comments, if any
                String sAction = e.Parameter;
                //Updating the default comments
                string mainComments;
                switch (sAction)
                {
                    case "Approve":
                        mainComments = "Approved.";
                        break;
                    case "Submit":
                        mainComments = "Submitted.";
                        break;
                    case "Cancel":
                        mainComments = "Canceled.";
                        break;
                    default:
                        mainComments = "";
                        break;
                }

                // Save the comments, if any
                if (Assignment != null)
                {
                    // Use assignment ID to find the row
                    // This is now uniform - the checklists do it too
                    CARComment pRow = PageContext.CARComments.FirstOrDefault(x => x.WFAssignId == Assignment.WFAssignId);
                    if (pRow == null)
                    {
                        pRow = new CARComment();

                        pRow.WFAssignId = Assignment.WFAssignId;
                        pRow.CARId = Assignment.WF.CARId;
                        pRow.UserId = UserId;
                        pRow.Timestmp = DateTime.Now;
                        pRow.Comments = mainComments;
                        pRow.Recommendation = 0;

                        PageContext.CARComments.Add(pRow);
                        PageContext.SaveChanges();
                    }

                    pRow.Timestmp = DateTime.Now;
                    pRow.Comments = mainComments;
                    pRow.Recommendation = 0;
                    PageContext.SaveChanges();
                }

                // This call saves the page-specific data!
                pPage.SaveChanges(e.Parameter);
            }
            e.Result = e.Parameter;
        }

        protected void cbMasterAction_Callback(object source, CallbackEventArgs e)
        {
            // I'm not sure the action can ever be "Save" at this point
            // This needs to be tightened up...
            if (!e.Parameter.StartsWith("Save"))
            {
                // Handle the workflow action

                // OK - if we get here - assume it's a workflow command
                String sAction = e.Parameter;

                // For now - find the workflow item
                if (Assignment != null)
                {
                    // We found a winner!
                    // OK - we should now have the assignment ID right in the workflow item!
                    WFEngine pWFEngine = GetWFEngine();

                    // Handle item with the specified action
                    pWFEngine.HandleItemAsync(Assignment.WFAssignId, sAction, null);

                    // We'll let the caller do the redirect now
                    // If it's submitted - we never want to stay on this page
                    // ASPxWebControl.RedirectOnCallback ("/Default.aspx");
                }
            }

            e.Result = e.Parameter;
        }


        // This is the same as above, except with the addition of a comment to the WF
        protected void cbModal_Callback(object sender, CallbackEventArgsBase e)
        {
            // Create the comment
            eCAR3Entities pContext = new eCAR3Entities();
            CARComment pComment = new CARComment();

            pComment.Comments = memoComments.Text;
            pComment.UserId = User.UserId;
            pComment.CARId = CAR.CARId;
            pComment.Flags = 0;
            pComment.Recommendation = 0;

            int wfAssignID = 0;
            if (Assignment != null)
            {
                wfAssignID = Assignment.WFAssignId;
            }
            else
            {
                //Find the associated WFAssign Id for admin
                wfAssignID = FindAdminAssignmentID();
            }

            pComment.WFAssignId = wfAssignID;
            pContext.CARComments.Add(pComment);
            pComment.Timestmp = DateTime.Now;
            pContext.SaveChanges();

            memoComments.Text = ""; //Clear the memo text
        }


        public int FindAdminAssignmentID()
        {
            return PageContext.WFAssigns.FirstOrDefault(x =>
                    x.WF.CARId == CAR.CARId &&
                    x.RoleId == "ADMIN").WFAssignId;
        }


        // This is the same as above, except with the addition of a comment to the WF
        protected void cbComments_Callback(object sender, CallbackEventArgsBase e)
        {
            String sAction = e.Parameter;

            //Updating the default comments
            string mainComments = "";
            switch (sAction)
            {
                case "Approve":
                    mainComments = "Approved.";
                    break;
                case "Revise/Hold":
                    mainComments = "Sending to creator for revision because - " + txtComments.Text;
                    break;
                case "Decline":
                    mainComments = "This was declined because - " + txtComments.Text;
                    break;
                default:
                    mainComments = "n/a";
                    break;
            }

            // Add the comment to the CAR - we'll also add it to the assignment
            // For now - find the workflow item
            if (Assignment != null)
            {
                eCAR3Entities pContext = new eCAR3Entities();
                CARComment pComment = new CARComment();

                pComment.Comments = mainComments;
                pComment.UserId = User.UserId;
                pComment.CARId = CAR.CARId;
                pComment.Flags = 0;
                pComment.Recommendation = 0;

                pComment.WFAssignId = Assignment.WFAssignId;
                pContext.CARComments.Add(pComment);
                pComment.Timestmp = DateTime.Now;
                pContext.SaveChanges();

                // We found a winner!
                // OK - we should now have the assignment ID right in the workflow item!
                WFEngine pWFEngine = GetWFEngine();

                // Handle item with the specified action
                pWFEngine.HandleItemAsync(Assignment.WFAssignId, sAction, mainComments);

                // Change to this if we put this in a callback!
                ASPxWebControl.RedirectOnCallback("/Default.aspx");
            }
        }

        // This method is now obsolete!
        public void btnWF_Clicked(object sender, EventArgs e)
        {
            ASPxButton pButton = (ASPxButton)sender;

            // This could change - and we should add a tool tip
            String sAction = pButton.Text;

            // Hopefully, this is always set!

            if (Assignment != null)
            {
                // We found a winner!
                // OK - we should now have the assignment ID right in the workflow item!
                WFEngine pWFEngine = GetWFEngine();

                // Handle item with the specified action
                pWFEngine.HandleItemAsync(Assignment.WFAssignId, sAction, null);

                // Change to this if we put this in a callback!
                ASPxWebControl.RedirectOnCallback("/Default.aspx");

                // This doesn't work in a callback!
                // Response.Redirect ("/Default.aspx");
            }
        }

        #region Properties

        public string RoleName
        {
            get
            {
                // For now - all assignments have roles
                // This doesn't have to be the case - but it is now
                return Assignment.Role.RoleName;
            }
        }

        #endregion

        #region PageData interface - just calls master

        public WFAssign Assignment
        {
            get
            {
                return Master.Assignment;
            }
            set
            {
                Master.Assignment = value;
            }
        }

        public vDashboard DashboardData
        {
            get
            {
                return Master.DashboardData;
            }
        }

        public CARMaster CAR
        {
            get
            {
                return Master.CAR;
            }
            set
            {
                Master.CAR = value;
            }
        }

        public int CARId
        {
            get
            {
                return Master.CARId;
            }
        }

        public CARUser User
        {
            get
            {
                return Master.User;
            }
        }

        public int UserId
        {
            get
            {
                return Master.UserId;
            }
        }

        public int UserBits
        {
            get
            {
                return Master.UserBits;
            }
        }

        public eCAR3Entities PageContext
        {
            get
            {
                return Master.PageContext;
            }
        }

        public ILog Logger
        {
            get
            {
                return Master.Logger;
            }
        }

        #endregion


    }
}