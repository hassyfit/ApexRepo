
using System.Configuration;
using System.Xml;
using System.Globalization;
using System.IO;

using log4net;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Reflection;
using System.Data;
using System.Collections;
using System.Text;
using DevExpress.Web;
using DevExpress.Web.ASPxTreeList;
using System.Data.SqlClient;
using eCAR3Lib;
using eCAR3Lib.Helpers;
using eCAR3Lib.Models;

namespace eCAR3Web
{
   public interface PageData
   {
      // This is ALL of the page data that we expect to get
      WFAssign Assignment { get; set; }

      vDashboard DashboardData { get; }
      CARMaster CAR { get; set; }
      int CARId { get; }
      CARUser User { get; }
      int UserId { get; }
      int UserBits { get; }

      eCAR3Entities PageContext { get; }
      ILog Logger { get; }

      WFEngine GetWFEngine ();
      MailHelper GetMailHelper ();
   }

   public static class SessionVars
   {
      public const string MkSpoofId = "M_SpoofId";
      public const string MkLoginId = "M_LoginId";
      public const string MkCurUserId = "M_CurUserId";
      public const string MkLoginEMail = "M_LoginEMail";
      public const string MkLoginName = "M_LoginName";
      public const string MkLoginUserBits = "M_LoginUserBits";
      public const string MkCurUserName = "M_CurUserName";
      public const string MkCurUserBits = "M_CurUserBits";

      public const string MkWA = "wa";
      public const string MkCAR = "c";
   }

   public partial class RootMaster : System.Web.UI.MasterPage, PageData
   {
      #region Logged in user


      #region Common page variables

      // Cache these things - at least for the life of the page
      private WFAssign MpAssignment = null;
      private vDashboard MpDashRow = null;
      private CARMaster MpCAR = null;
      private CARUser MpUser = null;
      private ILog MpLogger = null;

      // This is ALL of the page data that we expect to get
      public WFAssign Assignment
      {
         get
         {
            if (MpAssignment != null)
               return MpAssignment;

            if (Session [SessionVars.MkWA] == null)
               return null;

            int nAssignId = (int) Session [SessionVars.MkWA];
            MpAssignment = PageContext.WFAssigns.FirstOrDefault (x => x.WFAssignId == nAssignId);
            return MpAssignment;
         }
         set
         {
            if (value == null)
               Session [SessionVars.MkWA] = null;
            else
               Session [SessionVars.MkWA] = value.WFAssignId;
         }
      }

      public string BaseUrl
      {
         get
         {
            return Request.Url.Scheme + "://" + Request.Url.Authority + Request.ApplicationPath.TrimEnd ('/') + "/";
         }

      }

      public string MailTemplateDir
      {
         get
         {
            return Server.MapPath ("~/MailTemplates");
         }
      }

      public vDashboard DashboardData
      {
         get
         {
            if (MpDashRow != null)
               return MpDashRow;

            if (Session [SessionVars.MkCAR] == null)
               return null;

            int nCARId = (int) Session [SessionVars.MkCAR];
            MpDashRow = PageContext.vDashboards.FirstOrDefault (x => x.CARId == nCARId);
            return MpDashRow;
         }
      }

      public CARMaster CAR
      {
         get
         {
            if (MpCAR != null)
               return MpCAR;

            if (Session [SessionVars.MkCAR] == null)
               return null;

            int nCARId = (int) Session [SessionVars.MkCAR];
            MpCAR = PageContext.CARMasters.FirstOrDefault (x => x.CARId == nCARId);
            return MpCAR;
         }
         set
         {
            if (value == null)
               Session [SessionVars.MkCAR] = null;
            else
               Session [SessionVars.MkCAR] = value.CARId;
         }
      }

      public int CARId
      {
         get
         {
            if (CAR == null)
               return -1;

            return CAR.CARId;
         }
      }

      public CARUser User
      {
         get
         {
            if (MpUser != null)
               return MpUser;

            // This should actually not be null - although we have to handle session expiration
            int nUserId = (int) Session [SessionVars.MkCurUserId];
            MpUser = PageContext.CARUsers.FirstOrDefault (x => x.UserId == nUserId);
            return MpUser;
         }
      }

      public int UserId
      {
         get
         {
            return (int) Session [SessionVars.MkCurUserId];
         }
      }

      public int UserBits
      {
         get
         {
            return (int) Session [SessionVars.MkCurUserBits];
         }
      }

      public ILog Logger
      {
         get
         {
            if (MpLogger != null)
               return MpLogger;

            MpLogger = LogManager.GetLogger ("Web");
            return MpLogger;
         }
      }

      public eCAR3Entities PageContext { get; protected set; }

      #endregion

      // This code will be reproduced in the page base class - the master pages don't actually have inheritance
      protected string UserDisplayName
      {
         get
         {
            string sUserName = (string) Session [SessionVars.MkCurUserName];
            if (sUserName != null)
            {
               if (Session [SessionVars.MkSpoofId] != null && (int) Session [SessionVars.MkSpoofId] != (int) Session [SessionVars.MkLoginId])
                  sUserName += " (spoofed)";

               return sUserName;
            }

            return "No user logged in";
         }
      }

      #endregion

      #region PageData interface

      public WFEngine GetWFEngine ()
      {
         return new WFEngine (
            PageContext,
            Server.MapPath ("/eCARWF.xml"),
            ConfigurationManager.AppSettings,
            MailTemplateDir,
            BaseUrl);  // Base URL
      }

      public MailHelper GetMailHelper ()
      {
         return new MailHelper (ConfigurationManager.AppSettings, MailTemplateDir, BaseUrl);
      }

      #endregion

      #region Initialization

      protected void SetSessionInt (string key)
      {
         string sValue = Request [key];

         if (sValue == null || sValue.Length == 0)
         {
            Session [key] = null;
         }
         else
         {
            try
            {
               Session [key] = int.Parse (sValue);
            }
            catch
            {
               Session [key] = null;
            }
         }
      }

      protected void Page_Init (object sender, EventArgs e)
      {
         PageContext = new eCAR3Entities ();

         // For debugging only (with security turned off)
         String sUserEMail = Context.User.Identity.Name;
         if (sUserEMail.Length == 0 && Request.IsLocal)
         {
            String sDefaultUser = System.Configuration.ConfigurationManager.AppSettings ["DefaultUser"];
            if (sDefaultUser != null)
               sUserEMail = sDefaultUser;

         }

         // Context.User.Identity.Name - is actually the user's e-mail address
         // We'll get the name from the database
         if (sUserEMail != (string) Session [SessionVars.MkLoginEMail])
         {
            // This would actually fail if a user is logged in and THEN we delete him, since we don't check on every page load
            // We can change this if necessary, but this performs better

            CARUser pUserRow;

            pUserRow = PageContext.CARUsers.FirstOrDefault (x => x.UserEMail == sUserEMail);

            // Get our user
            // We are doing this on every page load for now
            // We can refine this later
            if (pUserRow == null)
            {
               Response.Redirect ("/Unauthorized.aspx");
               return;
            }

            // We can have a separate page for incorrect privileges!
            // For now - you need SOME privileges - this is just for testing
            if (pUserRow.UserRoles.Count == 0)
            {
               Response.Redirect ("/Unauthorized.aspx");
               return;
            }

            Session [SessionVars.MkLoginEMail] = pUserRow.UserEMail;
            Session [SessionVars.MkLoginId] = pUserRow.UserId;
            Session [SessionVars.MkLoginName] = pUserRow.UserName;
            Session [SessionVars.MkLoginUserBits] = pUserRow.RoleBits;

            // This should happen on the first login only
            Session [SessionVars.MkCurUserId] = pUserRow.UserId;
            Session [SessionVars.MkCurUserName] = pUserRow.UserName;
            Session [SessionVars.MkCurUserBits] = pUserRow.RoleBits;
         }

         // Set our common session variables
         // This could be a function with a try/catch!
         SetSessionInt (SessionVars.MkWA);
         SetSessionInt (SessionVars.MkCAR);
      }

      protected void Page_Load (object sender, EventArgs e)
      {
          eCAR3Entities pContext = new eCAR3Entities ();

          int nLoggedInUserBits = 0;
          if (Session [SessionVars.MkLoginUserBits] != null)
              nLoggedInUserBits = (int) Session [SessionVars.MkLoginUserBits];

          // Prevent spoof unless you are the right person...
          if ((nLoggedInUserBits & Role.ALLOWSPOOF) != 0)
          {
              cbSpoofUsers.Items.Clear ();

              // Add some logins here to the spoof panel
              foreach (CARUser pUser in pContext.CARUsers.Where(x=>x.Active).OrderBy(x => x.UserName))
              {
                   ListEditItem pItem = new ListEditItem (pUser.UserName, pUser.UserId);
                   cbSpoofUsers.Items.Add (pItem);
              }
          }
          else
          {
              pnlSpoof.Visible = false;
          }

          // FIX THIS! //#PFG
          int iBits = 0;
          try
          {
              iBits = (int) Session [SessionVars.MkCurUserBits];
          }
          catch
          {
          }

          LoadMenu ();
          ASPxLabel2.Text = Server.HtmlDecode ("Copyright &copy; " + DateTime.Now.Year + " by Smithfield Foods, Inc.");

        }

      protected void LoadMenu ()
      {
         XmlDocument pDoc = new XmlDocument ();
         pDoc.Load (MapPath ("/MainMenu.xml"));

         XmlNodeList pNodes = pDoc.SelectNodes ("MainMenu/Items/MenuItem");

         foreach (XmlElement pItemNode in pNodes)
            LoadMenu (pItemNode, HeaderMenu.Items);

      }

      protected void LoadMenu (XmlElement PpItemNode, DevExpress.Web.MenuItemCollection MpTarget)
      {
         // In case of error - enable everything
         bool bPermitted = true;
         string sItemFlags = PpItemNode.GetAttribute ("Roles");
         if (User != null && sItemFlags.Length > 0)
         {
            int nItemFlags = Convert.ToInt32 (sItemFlags, 16);
            if ((nItemFlags & MpUser.RoleBits) == 0)
               bPermitted = false;
         }

         if (bPermitted)
         {
            DevExpress.Web.MenuItem pItem = new DevExpress.Web.MenuItem ();

            String sName = PpItemNode.GetAttribute ("Name");
            if (sName.Length > 0)
               pItem.Name = sName;

            if (PpItemNode.GetAttribute ("ClientEnabled") == "true")
               pItem.ClientEnabled = true;

            pItem.Text = PpItemNode.GetAttribute ("Text");
            pItem.NavigateUrl = PpItemNode.GetAttribute ("NavigateUrl");

            MpTarget.Add (pItem);

            // Recurse to load child nodes
            foreach (XmlElement pChild in PpItemNode.SelectNodes ("Items/MenuItem"))
               LoadMenu (pChild, pItem.Items);
         }
         else
         {
            CheckPageSpoof (PpItemNode);
         }
      }

      protected bool CheckPageSpoof (XmlElement PpItemNode)
      {

         // A page or top menu is not permitted
         // Does this page match the current request?
         String sPageName = PpItemNode.GetAttribute ("NavigateUrl");
         if (sPageName.Length > 0)
         {
            int n = sPageName.LastIndexOf ('/');
            if (n != -1)
               sPageName = sPageName.Substring (n + 1);

            String sPath = Request.Path;
            n = sPath.LastIndexOf ('/');
            if (n != -1)
               sPath = sPath.Substring (n + 1);

            if (sPath == sPageName && !Request.IsLocal)
            {
               // Oops - this page is not permitted to you!
               Response.Redirect ("~/Unauthorized.aspx");
               return false;
            }
         }

         // Recurse to load child nodes
         foreach (XmlElement pChild in PpItemNode.SelectNodes ("Items/MenuItem"))
            if (!CheckPageSpoof (pChild))
               return false;

         return true;
      }

      #endregion

      #region User spoofing


      protected void btnSpoof_Click (object sender, EventArgs e)
      {
         // Not sure we can update the view - let's see what this does

         // We should add an error panel to the root view?

         if (cbSpoofUsers.SelectedItem == null)
            return;

         eCAR3Entities pContext = new eCAR3Entities ();
         ListEditItem pItem = cbSpoofUsers.SelectedItem;
         int nId = (int) pItem.Value;

         CARUser pUser = pContext.CARUsers.Single (x => x.UserId == nId);
         if (Session [SessionVars.MkCurUserId] != null && nId == (int) Session [SessionVars.MkCurUserId])
            Session [SessionVars.MkSpoofId] = null;   // Back to originally logged on user
         else
            Session [SessionVars.MkSpoofId] = nId;

         Session [SessionVars.MkCurUserId] = nId;
         Session [SessionVars.MkCurUserName] = pUser.UserName;
         Session [SessionVars.MkCurUserBits] = pUser.RoleBits;

         // Redirect to default page - this might not be a valid page any more!
         Response.Redirect ("~/Default.aspx");
      }

      #endregion

      #region Create CAR

      protected void cbCreateCAR_Callback (object source, CallbackEventArgs e)
      {
         // Create a new CAR here and redirect to its page...
         eCAR3Entities pContext = new eCAR3Entities ();
         CARMaster pCAR = new CARMaster ();

         string[] parameters = e.Parameter.Split(';');
         
         string orgInformation = parameters[0]; // orgId + '|' + locName + '|' + orgPath;
         string orgId = orgInformation.Split('|')[0];
         string orgLocationName = orgInformation.Split('|')[1];
         string orgPath = orgInformation.Split('|')[2];
         var divisonCharacter = orgPath.Substring(0, 1).ToUpper();
         
         //var threeCharacterLocation = orgLocationName.Replace(/\s +/ g, '').replace(/\./ g, '').substring(0, 3).toUpperCase();
         var threeCharacterLocation = orgLocationName.Substring(0, 3).ToUpper();
         var twoDigitYear = DateTime.Now.Year.ToString().Substring(2, 2);    // produces two digit year -- Ex. 2019 = "19"
         var threeDigitUniqueSequence = "XXX"; // The database trigger will make this a unique sequential number.
         var projectNumber = divisonCharacter + '-' + threeCharacterLocation + '-' + twoDigitYear + '-' + threeDigitUniqueSequence;

         string pillarInformation = parameters[1]; // pillarId + '|' + pillarName + '|' + decr;
         string pillarId = pillarInformation.Split('|')[0];
         string pillarName = pillarInformation.Split('|')[1];
         string pillarDescr = pillarInformation.Split('|')[2];  

         pCAR.OrgId = orgId;
         pCAR.ProjectNumber = projectNumber;
         pCAR.CreatedByUserId = UserId;
         pCAR.CreatedByName = UserDisplayName;
         pCAR.ProjectTitle = txtTitle.Text;
         pCAR.CreateTime = DateTime.Now;
         pCAR.ProjectTypeId = cbProjectType.Value.ToString();   // Set the dropdown ProjectTypeId
         pCAR.InterestRate = 0.000;                             // Updated Interest Rate to 0.000
         pCAR.ExchangeRate = 0;                                 // Updated Exchange Rate to 0
         pCAR.UsefulLifeYears = 0;                              // Updated Useful Life Years to 0
         pCAR.LeaseTermYears = 0;                               // Updated Lease Term Years to 0
         pCAR.NPV = 0;                                          // Updated NPV to 0
         pCAR.IRR = 0;                                          // Updated IRR to 0
         pCAR.CurrencyTypeId = 1;                               // Updated Currency Type to U.S. Dollar  
         
         //Set Desc fields to empty
         pCAR.ProjectDesc = "";                                 
         pCAR.ProjectReason = "";                               
         pCAR.ProjectJustification = "";
         pCAR.FiscalYear = DateTime.Now.Year;                   // Updated Fiscal Year to current year
         pCAR.PillarId = pillarId;                              // Set the dropdown PillarId
         pCAR.Status = "Active";

         pContext.CARMasters.Add (pCAR);
         pContext.SaveChanges (); // TODD: If we could remove this it may speed things up a bit.

         // We now have the CAR Id
         AddCostSheet (pContext, pCAR.CARId, 1);
         AddCostSheet (pContext, pCAR.CARId, 2);
         AddCostSheet (pContext, pCAR.CARId, 3);
         AddCostSheet (pContext, pCAR.CARId, 4);

         // Bootstrap the workflow process
         // This should probably not be here
         // This should be a function in the workflow engine!
         WFEngine pEngine = GetWFEngine ();

         WF pWF = pEngine.CreateWorkflow (pCAR.CARId);
         
         // This call assigns the workflow to an individual user
         string sURL = pEngine.Assign (pWF, "Create", "CREATE", UserId, null, pCAR.CARId.ToString ());

         // Redirect the users browser to the newly create CAR.
         //ASPxWebControl.RedirectOnCallback(sURL); // I removed this because the line below may be a tiny bit faster.
         cbCreateCAR.JSProperties ["cp_result"] = sURL; // Return to the client side where the JavaScript redirects to this CAR page. 
      }

      public void AddCostSheet (eCAR3Entities PpContext, int PnCARId, int PnCategory)
      {
         CostSheet pSheet = new CostSheet ();
         pSheet.CARId = PnCARId;
         pSheet.Category = PnCategory.ToString ();
         pSheet.Capital = 0;
         pSheet.Expense = 0;
         pSheet.OperLease = 0;
         pSheet.Percentage = 0;
         pSheet.CreateTime = DateTime.Now;

         PpContext.CostSheets.Add (pSheet);
      }

        #endregion


      #region Location

      protected void dsLoc_Selecting (object sender, Microsoft.AspNet.EntityDataSource.EntityDataSourceSelectingEventArgs e)
      {
         eCAR3Entities pContext = new eCAR3Entities ();

         // We need constants for these!
         List<String> pLocs = LocTreeCache.GetCreateLocsForUser (User.UserId, 0x0002);
         if (pLocs == null)
            return;

         StringBuilder sb = new StringBuilder ();

         int i = 0;

         // This works to get all of them
         foreach (string pLoc in pLocs)
         {
            if (i > 0)
               sb.Append (",");

            sb.Append("'" + pLoc + "'");
            i++;

         }

         e.DataSource.Where = string.Format ("it.RowKey in {{{0}}}", sb.ToString ());

      }

      protected void treeLocation_CustomJSProperties (object sender, TreeListCustomJSPropertiesEventArgs e)
      {
         eCAR3Entities pContext = new eCAR3Entities ();
         Hashtable pHash = new Hashtable ();

         foreach (vLocTree pRow in pContext.vLocTrees.Where (x => x.RowKey.StartsWith ("L")))
            pHash.Add (pRow.RowKey, pRow.Name);

         e.Properties ["cpNames"] = pHash;
      }

      protected void treeLocation2_CustomJSProperties (object sender, TreeListCustomJSPropertiesEventArgs e)
      {
         eCAR3Entities pContext = new eCAR3Entities ();
         Hashtable pHash = new Hashtable ();

         foreach (vLocTree pRow in pContext.vLocTrees.Where (x => x.RowKey.StartsWith ("L")))
            pHash.Add (pRow.RowKey, pRow.Name);

         e.Properties ["cpNames"] = pHash;
      }

      #endregion


      #region Project Type

      protected void treeProjectType2_CustomJSProperties(object sender, TreeListCustomJSPropertiesEventArgs e)
      {
            eCAR3Entities pContext = new eCAR3Entities();
            Hashtable pHash = new Hashtable();

            foreach (ProjectType pRow in pContext.ProjectTypes)
                pHash.Add(pRow.ProjectTypeId, pRow.Name);

            e.Properties["cpNames"] = pHash;
      }

        #endregion


      #region Pillar Type

        protected void treePillar2_CustomJSProperties(object sender, TreeListCustomJSPropertiesEventArgs e)
        {
            eCAR3Entities pContext = new eCAR3Entities();
            Hashtable pHash = new Hashtable();

            foreach (Pillar pRow in pContext.Pillars)
                pHash.Add(pRow.PillarId, pRow.Name);

            e.Properties["cpNames"] = pHash;
        }

        #endregion


        #region Login/Logout (not currently used)

        /* Not currently used - but could be added back later
        protected void Unnamed_LoggingOut (object sender, LoginCancelEventArgs e)
        {
           // Redirect to ~/Account/SignOut after signing out.
           string callbackUrl = Request.Url.GetLeftPart (UriPartial.Authority) + Response.ApplyAppPathModifier ("~/Account/SignOut");

           HttpContext.Current.GetOwinContext ().Authentication.SignOut (
               new AuthenticationProperties { RedirectUri = callbackUrl },
               OpenIdConnectAuthenticationDefaults.AuthenticationType,
               CookieAuthenticationDefaults.AuthenticationType);
        }

        protected void Unnamed_Click (object sender, EventArgs e)
        {
           if (!Request.IsAuthenticated)
           {
              HttpContext.Current.GetOwinContext ().Authentication.Challenge (
                  new AuthenticationProperties { RedirectUri = "/" },
                  OpenIdConnectAuthenticationDefaults.AuthenticationType);
           }
        }
        */

        #endregion

    }
}