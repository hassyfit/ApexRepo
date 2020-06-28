using DevExpress.Web;
using DevExpress.Web.ASPxTreeList;
using eCAR3Lib.Models;
using System;
using System.Collections;
using System.Data;
using System.EnterpriseServices;
using System.Linq;
using System.Web;
using System.Web.Services;

namespace eCAR3Web
{
    public partial class CarForm3 : WFPageBase
    {
        ProviderOptions MpOptions;
        public bool gSetReadOnly;
        public bool gAllowAuditDataEntry;
        public int gUserId;
        public bool gAllowDelete_OfAttachments;
        public CARUser gUser;
        public bool gUserHasRole_ADMIN;
        public bool gUserHasRole_SUPER;
        public bool TabsEnabled;

        protected void Page_Load(object sender, EventArgs e)
        {
            gUserId = Master.UserId;
            gUser = User;
            TabsEnabled = true;
            MpOptions = new ProviderOptions();

            //Set the file name (for multiple file downloads) to Project Number initially
            fmAttachments.SettingsEditing.DownloadedArchiveName = Master.CAR.ProjectNumber.Replace("/", "-").Trim();
            fmAttachments.CustomFileSystemProvider = new AttachmentFileProvider(fmAttachments.Settings.RootFolder, MpOptions, CARId);

            // First Time in Page
            if (!IsPostBack)
            {
                PreventSpoofing();
                if (Assignment == null)
                    Assignment = FindAssignment();
            }

            // Every time in Page
            RestrictPermissions();

            if (Assignment != null)
            {
                SetCreatorsPermissions();
                SetVpopAnalPermissions();
                SetAdminsPermissions();
                SetOthersPermissions();
            }

            SetBasicAdminsPermissions();
            SetSupersPermissions();
            AreRequiredFieldsDone();
        }

        

        private void RestrictPermissions()
        {
            gSetReadOnly = true;
            gAllowAuditDataEntry = false;
            gUserHasRole_ADMIN = false;
            gUserHasRole_SUPER = false;
            fmAttachments.SettingsUpload.Enabled = false;
            fmAttachments.SettingsEditing.AllowDelete = false;
            gAllowDelete_OfAttachments = false;
        }

        private void PreventSpoofing()
        {
            var pRow = PageContext.vCARViews.FirstOrDefault(x => x.CARId == CAR.CARId && x.UserId == Master.UserId);
            if (pRow != null) return;
            Response.Redirect("~/Unauthorized.aspx");
        }

        private void SetSupersPermissions()
        {
            if (!User.HasRole(Role.SUPER)) return;
            gSetReadOnly = false;
            gAllowAuditDataEntry = true;
            gUserHasRole_SUPER = true;
            fmAttachments.SettingsUpload.Enabled = true;
            fmAttachments.SettingsEditing.AllowDelete = true;
            gAllowDelete_OfAttachments = true;
        }

        private void SetCreatorsPermissions()
        {
            if (!User.HasRole(Role.CREATE_CAR) || Assignment.CurStatus != "Assigned" ||
                (Assignment.StepName != "Create" && Assignment.StepName != "Revise")) return;

            gSetReadOnly = false;
            fmAttachments.SettingsUpload.Enabled = true;
            fmAttachments.SettingsEditing.AllowDelete = true;
            gAllowDelete_OfAttachments = true;
        }

        // Set Minimal permissions for ADMINs regardless of assignment 
        private void SetBasicAdminsPermissions()
        {
            if (!User.HasRole(Role.ADMIN)) return;
            gUserHasRole_ADMIN = true;
            fmAttachments.SettingsUpload.Enabled = true;
            fmAttachments.SettingsEditing.AllowDelete = true;
            gAllowDelete_OfAttachments = true;
        }

        private void SetAdminsPermissions()
        {
            if (User.HasRole(Role.ADMIN) && Assignment.StepName == "Admin") // (Assignment.StepName != "Create" || Assignment.StepName != "Revise" ||
            //                                 Assignment.StepName != "Collaboration" ||
            //                                 Assignment.StepName != "VPLevel" || Assignment.StepName != "ExecLevel"))
            {
                gSetReadOnly = false;
            }
        }

        private void SetVpopAnalPermissions()
        {
            if (Assignment.RoleId != "VPOPANAL") return;
            gSetReadOnly = true;
            gAllowAuditDataEntry = true;
        }

        private void SetOthersPermissions()
        {
            if (Assignment.CurStatus != "Assigned" || User.HasRole(Role.CREATE_CAR) ||
                Assignment.StepName != "VPLevel" && Assignment.StepName != "ExecLevel" &&
                Assignment.StepName != "CLevel") return;
            gSetReadOnly = true;
            fmAttachments.SettingsUpload.Enabled = true;
            fmAttachments.SettingsEditing.AllowDelete = false;
            gAllowDelete_OfAttachments = false;
        }

        #region #CustomColumnDisplay
        // #PFG - Does this even work?

        protected void fmAttachments_CustomDisplay(object source, FileManagerDetailsViewCustomColumnDisplayTextEventArgs e)
        {
            if (e.Column.Name == "Description")
            {
                e.DisplayText = PageContext.vAttachments.FirstOrDefault(x =>
                        x.CARId == CAR.CARId &&
                        x.FileName == e.File.Name).Descr ?? "--"; // Prevents NULLS on drag and drop
            }
            else if (e.Column.Name == "Size")
            {
                e.DisplayText = FormatByteSize(e.File.Length);
            }
            else
            {
                e.DisplayText = DateTime.Now.ToString();
            }
        }

        #endregion #CustomColumnDisplay

        public static string FormatByteSize(long bytes)
        {
            string[] suffix = { "B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB" };
            int index = 0;
            do
            {
                bytes /= 1024;
                index++;
            }
            while (bytes >= 1024);
            return $"{bytes:0.00} {suffix[index]}";
        }

        [WebMethod]
        public static string OnSubmit(string name, bool isGoing, string returnAddress)
        {
            return "it worked";
        }

        public void AreRequiredFieldsDone()
        {
            vWorklist wList = PageContext.vWorklists.FirstOrDefault(x => x.CARId == CAR.CARId);

            if (wList != null && wList.CurStepName == "Create")
            {
                CARMaster eCar = PageContext.CARMasters.FirstOrDefault(x => x.CARId == CAR.CARId);

                var hasProjTitle = !string.IsNullOrWhiteSpace(eCar.ProjectTitle);
                var hasOrgId = !string.IsNullOrWhiteSpace(eCar.OrgId);
                var hasProjManagerId = (eCar.ProjManagerId != null);
                var hasCostCenterNumber = !string.IsNullOrWhiteSpace(eCar.CostCenterNumber);
                var hasCurrencyTypeId = (eCar.CurrencyTypeId != null);
                var hasProjTypeId = !string.IsNullOrWhiteSpace(eCar.ProjectTypeId);
                var hasPillarId = !string.IsNullOrWhiteSpace(eCar.PillarId);
                var hasStartDate = (eCar.StartDate != null);
                var hasEndDate = (eCar.EndDate != null);
                var hasInCapPlanFlag = (eCar.InCapPlanFlag != null);
                var hasSubstitutionFlag = (eCar.SubstitutionFlag != null);
                var hasAssetsAffectedFlag = (eCar.AssetsAffectedFlag != null);
                var hasCompBidsFlag = (eCar.CompBidsFlag != null);
                var hasVendorContractFlag = (eCar.VendorContractFlag != null);
                var hasExcessCapacityFlag = (eCar.ExcessCapacityFlag != null);
                var hasSpecMaintFlag = (eCar.SpecMaintFlag != null);
                var hasExcessMaintFlag = (eCar.ExcessMaintFlag != null);
                var hasLeaseReqFlag = (eCar.LeaseReqFlag != null);
                var hasSimplePaybackFlag = (eCar.SimplePaybackFlag != null);
                //If Lease is Required, then check other required fields, otherwise pass them
                var hasLeaseOwnFlag = (eCar.LeaseReqFlag == true) ? (eCar.LeaseOwnFlag != null) : true;
                var hasLeaseBargainOptionFlag = (eCar.LeaseReqFlag == true) ? (eCar.LeaseBargainOptionFlag != null) : true;
                var hasLeaseNPVFlag = (eCar.LeaseReqFlag == true) ? (eCar.LeaseNPVFlag != null) : true;

                TabsEnabled = (hasOrgId && hasProjTitle && hasProjManagerId && hasCostCenterNumber && hasProjTypeId && hasCurrencyTypeId
                                && hasPillarId && hasStartDate && hasEndDate && hasInCapPlanFlag && hasSubstitutionFlag && hasAssetsAffectedFlag
                                && hasCompBidsFlag && hasVendorContractFlag && hasExcessCapacityFlag && hasSpecMaintFlag && hasExcessMaintFlag
                                && hasLeaseReqFlag && hasSimplePaybackFlag && hasLeaseOwnFlag && hasLeaseBargainOptionFlag && hasLeaseNPVFlag);
            }
        }

        public override WFAssign FindAssignment()
        {
            var assignment = new WFAssign();
            try
            {
                assignment = PageContext.WFAssigns.FirstOrDefault(x =>
                    x.WF.CARId == CAR.CARId &&
                    x.CurStatus == "Assigned" &&
                    x.UserId == UserId);
            }
            catch (Exception ex)
            {
                // This exception happens when carform3.aspx is called without a target car Id 
                // For now redirect to default.aspx.
                // This should never happen in the wild, only for developers. #PFG-REFACTOR this. Kludge.
                var x = ex;
                if (x.Message == "Non-static method requires a target.")
                { Response.Redirect("Default.aspx"); }
            }

            return assignment;
        }

        //protected void btnSubmit_Click(object sender, EventArgs e)
        //{
        //    //MailHelper pHelper = GetMailHelper ();
        //    //pHelper.SendMail (txtTo.Text, txtSubject.Text, txtBody.Text);

        //}

        protected void fmAttachments_FileUploading(object source, FileManagerFileUploadEventArgs e)
        {
            //On upload - we want to overwrite
            MpOptions.AllowOverwrite = true;
        }

        protected void fmAttachments_ItemDeleting(object source, FileManagerItemDeleteEventArgs e)
        {
            //On delete - we need to find the file
            MpOptions.AllowOverwrite = false;
            MpOptions.UserId = User.UserId;
        }

        protected void treeLocation_CustomJSProperties(object sender, TreeListCustomJSPropertiesEventArgs e)
        {
            eCAR3Entities pContext = new eCAR3Entities();
            Hashtable pHash = new Hashtable();

            foreach (vLocTree pRow in pContext.vLocTrees.Where(x => x.RowKey.StartsWith("L")))
                pHash.Add(pRow.RowKey, pRow.Name);

            e.Properties["cpNames"] = pHash;
        }

        protected void treePillar_CustomJSProperties(object sender, TreeListCustomJSPropertiesEventArgs e)
        {
            eCAR3Entities pContext = new eCAR3Entities();
            Hashtable pHash = new Hashtable();

            foreach (Pillar pRow in pContext.Pillars)
                pHash.Add(pRow.PillarId, pRow.Name);

            e.Properties["cpNames"] = pHash;
        }

        protected void gridSpendForecast_DataBinding(object sender, EventArgs e)
        {

        }

        protected void gridSpendForecast_CellEditorInitialize(object sender, ASPxGridViewEditorEventArgs e)
        {

        }
    }
}