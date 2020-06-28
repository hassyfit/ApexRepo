<%@ Page Title="CARForm3" Language="C#" MasterPageFile="~/WFMain2.master" AutoEventWireup="true" CodeBehind="CarForm3.aspx.cs" Inherits="eCAR3Web.CarForm3" %>

<%@ Register Assembly="DevExpress.Web.v18.1, Version=18.1.4.0, Culture=neutral, PublicKeyToken=b88d1754d700e49a" Namespace="DevExpress.Data.Linq" TagPrefix="dx" %>

<%@ MasterType VirtualPath="~/WFMain2.master" %>

<%@ Register Assembly="DevExpress.Web.ASPxTreeList.v18.1, Version=18.1.4.0, Culture=neutral, PublicKeyToken=b88d1754d700e49a" Namespace="DevExpress.Web.ASPxTreeList" TagPrefix="dx" %>
<%@ Register Src="~/WFPath.ascx" TagPrefix="uc1" TagName="WFPath" %>
<%@ Register Src="~/CommentsCtrl.ascx" TagPrefix="uc1" TagName="CommentsCtrl" %>


<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <meta charset="utf-8" />

    <link rel="stylesheet" type="text/css" href="/Content/Styles/jquery-ui.css" />
    <link rel="stylesheet" type="text/css" href="/Content/Styles/dx.common.css" />
    <link rel="stylesheet" type="text/css" href="/Content/Styles/dx.light.css" />

    <script src="/Scripts/jquery-ui.js" type="text/javascript"></script>
    <script src="/Scripts/pptxgen.min.js" type="text/javascript"></script>

    <script src="/Scripts/Common.js?v=41" type="text/javascript"></script>
    <script src="/Scripts/CARForm3.js?v=41" type="text/javascript"></script>

    <style>
        .form-row {
            display: flex;
            margin-bottom: 29px;
        }

        .form-row:last-child {
            margin-bottom: 0px;
        }

        .margin-top-10 {
            margin-top: 10px;
        }

        .float-left {
            float: left;
        }

        .float-right {
            float: right;
        }

        .display-inline {
            display: inline;
        }

        .display-inline-block {
            display: inline-block;
        }

        .width-200 {
            width: 200px;
        }

        .clear-both {
            clear: both;
        }

        .gj-display-none {
            display: none;
        }

        .buttonWithMargin {
            margin-left: 10px;
        }
    </style>

    <style>
        .ui-controlgroup-vertical {
            width: 150px;
        }

        .ui-controlgroup.ui-controlgroup-vertical > button.ui-button,
        .ui-controlgroup.ui-controlgroup-vertical > .ui-controlgroup-label {
            text-align: center;
        }

        #car-type-button {
            width: 120px;
        }

        .ui-controlgroup-horizontal .ui-spinner-input {
            width: 20px;
        }
    </style>

    <script>
        "use strict"; // This enforces us always having to declare variables!!!!

        //var operationUriPrefix;
        var gSetReadOnly = <%=gSetReadOnly.ToString().ToLower()%>;
        var gAllowAuditDataEntry = '<%=gAllowAuditDataEntry.ToString().ToLower()%>';
        var gUserId = '<%=gUserId.ToString()%>';
        var gUserHasRole_ADMIN = '<%=gUserHasRole_ADMIN.ToString().ToLower()%>';
        var gUserHasRole_SUPER = '<%=gUserHasRole_SUPER.ToString().ToLower()%>';
        var TabsEnabled = '<%=TabsEnabled.ToString().ToLower()%>';  //This is the TabsEnabled object
        var gCar; // This is the new CARMaster object. We use this throughout.
        var gCarId; // This is the CARId, which is used throughout.
        var gOrg;   // This is the new Org object.
        var gAssignmentId; //
        var gCostSheetArray = [];  //This holds the Cost Sheet array
        var FixedCostsArray = [];
        var ProjectArray = [];
        var ForecastArray = [];
        var TotalProjectedCapitalSpending = 0;
        var TotalAmountForecast = 0;
        var AreRequiredFieldsDone = false;

        // This formulates the operationUri, which is used throughout.
        var url1 = window.location.href.split('https://')[1];
        var url2 = url1.split('/')[0];
        var operationUriPrefix = 'https://' + url2 + '/';

        var gUser; // CARUser object.
        var gAssignment; // WFAssign object.

        // HTML Editor vars --> Change Later #PFG
        var projectDescEditor;
        var projectReasonEditor;
        var projectJustificationEditor;

        var editorToolbarOptions = [
            ['bold', 'italic', 'underline', 'strike'],        // toggled buttons
            ['blockquote', 'code-block'],
            [{ 'header': 1 }, { 'header': 2 }],               // custom button values
            [{ 'list': 'ordered' }, { 'list': 'bullet' }],
            [{ 'script': 'sub' }, { 'script': 'super' }],     // superscript/subscript
            [{ 'indent': '-1' }, { 'indent': '+1' }],         // outdent/indent
            [{ 'direction': 'rtl' }],                         // text direction
            ['link', 'image'],
            [{ 'size': ['small', false, 'large', 'huge'] }],  // custom dropdown
            [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
            [{ 'color': [] }, { 'background': [] }],          // dropdown with defaults from theme
            [{ 'font': [] }],
            [{ 'align': [] }],
            ['clean']                                         // remove formatting button
        ];

        var editorOptions = {
            modules: {
                toolbar: editorToolbarOptions,
                //readOnly: false
            },
            theme: 'snow'
        };
        // --- end HTML Editors

        $(window).bind("load", function () {
            // We are doing this so our css is applied prior to displaying to the user.
            // This event fires after document.ready(), when all the files are loaded. WE NEED TO optimize, minify in the future.
            console.log('In window.load().');
            setTimeout(function () {
                document.getElementById('tabs').style.display = 'inline'; // Delay 1/2 second to give the jquery-ui tab control time to get it's css applied.
            }, 500);
        });

        $(document).ready(function () {
            try
            {
                lpSpinner.SetText('Loading the eCar...');
                lpSpinner.Show();

                console.log('In document.ready().');
                console.log('gUserHasRole_SUPER: ' + gUserHasRole_SUPER + ', gUserHasRole_SUPER: ' + gUserHasRole_SUPER);

                if (gUserHasRole_ADMIN == 'true' || gUserHasRole_SUPER == 'true') {
                    // Displaying RACI tab.
                    $('[href="#tabs-9-RACI"]').closest('li').show();
                }

                //For fields that require only decimal values
                $('.OnlyDecimal').keypress(function (event) {
                    return isNumeric(event, this);
                });

                console.log('In CarForm3.aspx.document.ready(). gUserId: ' + JSON.stringify(gUserId));
                // This is when the page loads. Here are the things that need to happen:
                gCarId = getUrlParameter('c');
                gAssignmentId = getUrlParameter('wa');
                console.log('gCarId: ' + gCarId + ', gSetReadOnly: ' + gSetReadOnly + ', gAllowAuditDataEntry: ' + gAllowAuditDataEntry + ', gAssignmentId: ' + gAssignmentId);

                // Load the CARUser object.
                $.ajax({
                    url: operationUriPrefix + "odata/CARUsers?$filter=UserId eq " + gUserId,
                    dataType: "json"
                }).done(function (result) {
                    try {
                        gUser = result.value;
                        //console.log('In CarForm3.aspx.document.ready(). gUser: ' + JSON.stringify(gUser));
                        initializeThePage();

                    } catch (e) {
                        console.log('Exception in CarForm3.aspx.document.ready(): ' + e.message + ', ' + e.stack);
                    }
                });
            }
            catch (e) {
                console.log('Exception in CarForm3.aspx.document.ready(): ' + e.message + ', ' + e.stack);
            }
        });

        function removeTags(str) {
            if ((str === null) || (str === ''))
                return false;
            else
                str = str.toString();
            return str.replace(/(<([^>]+)>)/ig, '');
        };

        function initializeThePage()
        {
            try
            {
                console.log('In CarForm3.aspx.initializeThePage(' + gSetReadOnly + ', ' + gAllowAuditDataEntry + ').');

                var deferred = $.Deferred();
                deferred
                    .then(
                        function () {
                            projectDescEditor = new Quill('#ProjectDesc', editorOptions);
                        },
                        function () {
                            console.log('In CarForm3.aspx.initializeThePage(): Failure in setting projectDescEditor options.');
                        }
                    ).then(
                        function () {
                            projectReasonEditor = new Quill('#ProjectReason', editorOptions);
                        },
                        function () {
                            console.log('In CarForm3.aspx.initializeThePage(): Failure in setting projectReasonEditor options.');
                        }
                    ).then(
                        function () {
                            projectJustificationEditor = new Quill('#ProjectJustification', editorOptions);
                        },
                        function () {
                            console.log('In CarForm3.aspx.initializeThePage(): Failure in setting projectJustificationEditor options.');
                        }
                    ).then(
                        function () {
                            $('#tabs').tabs({
                                heightStyle: '750px', // Makes them all the height of the parent tab.
                                activate: function (event, ui) {
                                    var tabId = ui.newPanel.attr('id');
                                    if (tabId == 'tabs-9-RACI') {
                                        // This is the RACI tab.
                                        populateRaciTab();
                                    }
                                    else if (tabId == 'tabs-7-ATTACHMENTS') {
                                        fmAttachments.AdjustControl(); // This gets the attachments control to adjust to the available size.
                                    }
                                    else if (tabId == 'tabs-4-SPENDFORECAST') {
                                        // When we switch to the 'SPEND FORECAST' tab, we need to make sure that the Start and Completion dates have been filled out on the "Basic Info" tab.
                                        var startDate = new Date(gCar.StartDate);
                                        var endDate = new Date(gCar.EndDate);

                                        //console.log('The "Spend Forecast" tab has been selected. Start date: ' + startDate + ', End date: ' + endDate);
                                        if (startDate == null || endDate == null) {
                                            alert('1: Before you can enter "Spend Forecast" information, you must choose "Project Start Date" and "Completion Date" on the "BASIC INFO" tab.');
                                            $('#tabs').tabs({ active: 0 }); // The dates weren't filled out, so take the user back to the 'BASIC INFO' tab.
                                        }
                                    }
                                }
                            });

                            $("#tabs-ExistingComments-Approvers").tabs({ collapsible: true });
                            $("#tabs-ExistingComments-Collaborators").tabs({ collapsible: true });
                            $(".controlgroup").controlgroup();
                            $(".controlgroup-vertical").controlgroup({ "direction": "vertical" });

                            if (gSetReadOnly == true) {
                                console.log('gSetReadOnly == true');
                                populateCarDataReadOnly();
                            }
                            else if (gSetReadOnly == false) {
                                console.log('gSetReadOnly == false');
                                populateCarDataNotReadOnly();

                                //// TO-DO: May need to take out eventually
                                // Remove readonly attributes from the controls.
                                //var controls = [];
                                //controls.push('ProjectTitle', 'CostCenterNumber', 'CostCenterDesc', 'ExchangeRate', 'CapitalPlanItemId', 'ProjectReason', 'ProjectJustification');
                                //for (var i = 0; i < controls.length; i++) {
                                //    console.log('removing readonly attribute on ' + controls[i]);
                                //    document.getElementById(controls[i]).removeAttribute('readonly');
                                //}
                            }
                            else {
                                console.log('Error in CarForm3.aspx.initializeThePage(' + gSetReadOnly + ', ' + gAllowAuditDataEntry + '): Invalid readOnly value');
                            }
                        },
                        function () {
                            console.log('In CarForm3.aspx.initializeThePage(): Failure in populating CAR Data.');
                        });
                deferred.resolve();
            }
            catch (e) {
                console.log('Exception in CarForm3.aspx.initializeThePage:(' + gSetReadOnly + ', ' + gAllowAuditDataEntry + '): ' + e.message + ', ' + e.stack);
            }
        }

        Date.daysBetween = function (date1, date2)
        {
            try {
                console.log('In CARForm3.aspx.Date.daysBetween(): date1: ' + date1 + ', date2: ' + date2);

                var sDate = new Date(date1);
                var eDate = new Date(date2);

                //Get 1 day in milliseconds
                var one_day = 1000 * 60 * 60 * 24;
                // Convert both dates to milliseconds
                var date1_ms = sDate.getTime();
                var date2_ms = eDate.getTime();
                // Calculate the difference in milliseconds
                var difference_ms = date2_ms - date1_ms;
                // Convert back to days and return
                return Math.round(difference_ms / one_day);
            }
            catch (e) {
                console.log('Exception in CARForm3.aspx.Date.daysBetween(), Calculate "# of Days": ' + e.message + ', ' + e.stack);
            }
        }

        function LeaseReq_Changed() {
            LeaseReqFlag_OnChange();
            AreRequiredFieldsCompleted();
        }

        function InCapPlanChanged() {
            InCapPlanFlag_OnChange();
            AreRequiredFieldsCompleted();
        }

        function DateChanged() {
            deStartEnd_DateChanged();
            AreRequiredFieldsCompleted();
        }

        function LeaseTypeChanged() {
            LeaseType_OnChange();
            AreRequiredFieldsCompleted();
        }


        function deStartEnd_DateChanged() {
            try
            {
                console.log('In CARForm3.aspx.deStartEnd_DateChanged().');
                // Check if there are entries on the "Spend Forecast" tab. If so, prompt the user to allow deletion of them, or cancel the date change.
                var spendForecastRowCount = jsGridSpendForecast.data; //gridSpendForecast.GetVisibleRowsOnPage(); // returns 0 or anumber greater than 0.
                console.log('spendForecastRowCount: ' + spendForecastRowCount);
                if (spendForecastRowCount && spendForecastRowCount > 0) {
                    // There are items. Prompt the user to prceed or cancel.
                    if (confirm("You have already entered Spend Forecast information, and it is dependant upon the Start and Completion dates. Do you wish to clear the Spend Forecast information?")) {
                        console.log('In CARForm3.aspx.deStartEnd_DateChanged(). The user has selected to clear the Spend Forecast information.');
                        for (var i = 0; i < spendForecastRowCount; i++) {
                            gridSpendForecast.DeleteRow(i);
                        }
                    } else {
                        console.log('In CARForm3.aspx.deStartEnd_DateChanged(). The user has selected NOT to clear the Spend Forecast information.');

                        //console.log('control name>>>>>>>>>>>>>>>>>>>>>>>>>>> ' + e.name);
                        //var myDate = new Date(2011, 1, 1);
                        //s.SetDate(globalLatestSelectedDatePickerArchivedDateValue); // Sets the date back to what it was previously for this control.

                        //e.cancel; // This reverts the calendar control back to it's original value.
                    }
                } else {
                    // Include from UpdateBasicControls!!!!!!!!!!!!!!!!!!!!!!!!!
                    // Calculate "# of Days".
                    try {
                        console.log('Getting Start & End Dates');
                        var startDate = $("#StartDate").datepicker('getDate');
                        var endDate = $("#EndDate").datepicker('getDate');
                        if (startDate !== null && endDate !== null) { // if any date selected in datepicker
                            var daysTotal = Date.daysBetween(startDate, endDate);
                            //console.log('daysTotal: ' + daysTotal);

                            if (daysTotal == -1)
                                $('#numberOfDays').val('Invalid date range');
                            else
                                $('#numberOfDays').val(daysTotal + ' days');
                        }

                        var startDate = $("#StartDate").datepicker('getDate');
                        var endDate = $("#EndDate").datepicker('getDate');
                        if (startDate !== null && endDate !== null) { // if any date selected in datepicker
                            var daysTotal = Date.daysBetween(startDate, endDate);
                            console.log('daysTotal: ' + daysTotal);

                            // Display the number of days based on the start/end dates
                            if (daysTotal == -1)
                                $('#numberOfDays').val('Invalid date range');
                            else
                                $('#numberOfDays').val(daysTotal + ' days');
                        }

                    } catch (e) {
                        console.log('Exception in CARForm3.aspx.deStartEnd_DateChanged()., Calculate "# of Days": ' + e.message + ', ' + e.stack);
                    }
                }
            } catch (e) {
                console.log('Exception in CARForm3.aspx.deStartEnd_DateChanged(): ' + e.message + ', ' + e.stack);
            }
        }

        function toggleFileSelect() {
            console.log('In CARSummaryCtrl.ascx.toggleFileSelect().');
            var allFiles = fmAttachments.GetItems();                                //Get all Files
            var selFiles = fmAttachments.GetSelectedItems();                        //Get selected Files
            if (selFiles == undefined || selFiles.length < allFiles.length)
            {
                //Not every file is selected --- select all files
                for (var index = 0; index < allFiles.length; index++)
                {
                    fmAttachments.GetItems()[index].SetSelected('true');
                    console.log('File: ' + fmAttachments.GetItems()[index] + ' is selected.');
                }
            }
            else
            {
                //All files are selected --- unselect all files
                fmAttachments.Refresh();
                console.log('All files are unselected.');
            }
        }

        function PerformWorkflowAssignmentReversalFromDoneToAssigned(wfAssignId) {
            //lpSpinner.Show();
            $.ajax({
                url: operationUriPrefix + "api/eCarApi/GetConfirmationToPerformWorkflowAssignmentReversalFromDoneToAssigned?wfAssignId=" + wfAssignId,
                dataType: "json"
            }).done(function (result) {
                try {
                    //lpSpinner.Hide();
                    console.log('In CarForm3.aspx.GetConfirmationToPerformWorkflowAssignmentReversalFromDoneToAssigned(): result: ' + result);
                    var res = JSON.parse(result);
                    //console.log('result: ' + result);
                    if (res.ableToProceed != 'true') {
                        alert(res.message);
                    } else {
                        if (confirm(res.message)) { // The web service sends a summary of the changes that will be made. The user can decide whether to proceed, or not.
                            // The user has decided to proceed.
                            $.ajax({
                                url: operationUriPrefix + "api/eCarApi/GetPerformWorkflowAssignmentReversalFromDoneToAssigned?wfAssignId=" + wfAssignId + "&checksum=" + res.checksum, // Pass back the checksum to ensure nothing has changed...
                                dataType: "json"
                            }).done(function (result) {
                                try {
                                    //lpSpinner.Hide();
                                    var res = JSON.parse(result);
                                    alert(res.message); // The web service sends a summary of actions and status. This is displayed to the user.
                                    populateRaciTab();
                                } catch (e) {
                                    //lpSpinner.Hide();
                                    console.log('Exception in document.ready(): ' + e.message + ', ' + e.stack);
                                }
                            });
                        } else {
                            // The user has decided not to proceed.
                            console.log('In CARForm3.aspx.PerformWorkflowAssignmentReversalFromDoneToAssigned(). The user has selected NOT to reverse from done to assigned.');
                            alert('You have decided not to proceed. No changes were made.');
                        }
                    }
                } catch (e) {
                    //lpSpinner.Hide();
                    console.log('Exception in document.ready(): ' + e.message + ', ' + e.stack);
                }
            });
        }

        function displayAssignmentActionButtons(wfAssignId) {
            // This displays the appropriate button at the top of the page
            //// Do not enable workflow buttons if the item is already done

            //// Adjust buttons on the fly
            //WFEngine pEngine = GetWFEngine ();

            //ActionInfo [] aActions = pEngine.GetActions (Assignment.StepName, Assignment.RoleId);
            //foreach (ActionInfo pAction in aActions)
            //{
            //   ASPxButton pButton = lsButtons [i];
            //   pButton.Text = pAction.Action;
            //   pButton.ToolTip = pAction.Tooltip;
            //   if (pAction.RequireComments)
            //      pButton.ClientSideEvents.Click = "onWFComments";
            //   else
            //      pButton.ClientSideEvents.Click = "onWFButtonClick";

            //   pButton.Visible = true;
            //   i++;
            //}
            $.ajax({
                url: operationUriPrefix + "api/eCarApi/GetAssignmentActions?stepName=Collaboration&roleId=PM",
                dataType: "json"
            }).done(function (result) {
                try {
                    var actions = JSON.stringify(result);
                    for (var i = 0; i < actions.length; i++) {
                        console.log('action ' + i + ': ' + actions[i].ActionName);
                    }
                }
                catch (e) {
                    console.log('Exception in document.ready(): ' + e.message + ', ' + e.stack);
                }
            });
        }

        function getUrlParameter(sParam) {
            var sPageURL = window.location.search.substring(1),
                sURLVariables = sPageURL.split('&'),
                sParameterName,
                i;

            for (i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('=');

                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : decodeURIComponent(sParameterName[1]);
                }
            }
        };

        function generateLabel(id, newValue)
        {
            console.log('In generateLabel(). id: ' + id + ', value: ' + newValue);
            try
            {
                //empty the div
                $('#div' + id).empty();

                //Create the label element
                var label = $('<label id="' + id + '">').text(newValue);

                //Append to the corresponding div
                $('#div' + id).append(label);

                //Set element to readonly
                $('#div' + id).prop('readonly', true);
            }
            catch (e) {
                console.log('Exception in generateLabel*(: ' + e.message + ', ' + e.stack);
            }
        };

        function populateRaciTab() {
            // Populate the "RACI" tab.
            console.log('In populateRaciTab().');

            try 
            {
                if (gUserHasRole_SUPER !== 'true' && gUserHasRole_ADMIN !== 'true') {
                    alert('The RACI tab is only available to users that have role "SUPER".');
                }
                else {
                    //var CARId = getUrlParameter('c');

                    var deferred = $.Deferred();
                    deferred
                        .then(
                            function () {
                                lpSpinner.SetText('Loading the latest RACI configuration and status...');
                                lpSpinner.Show();
                            },
                            function () {
                                console.log('In CarForm3.aspx.initializeThePage(): Failure in setting projectDescEditor options.');
                            }
                        ).then(
                            function () {
                                //var orgId = document.getElementById('raci-location').value;
                                //var projectTypeId = document.getElementById('raci-projectType').value;

                                var orgId = gCar.OrgId; // Todd: We should probably be looking up to the control, like this >> //document.getElementById('location').value;
                                //var projectTypeId = document.getElementById('ProjectTypeId').value;
                                var projectTypeId = (gSetReadOnly) ? $('#projectType').text() : $("#ProjectTypeId option:selected").text();

                                console.log('In populateRaciTab(). orgId:' + orgId + ', projectTypeId: ' + projectTypeId);

                                if (!orgId) {
                                    alert('Please select a "Location" before clicking the Refresh button.');
                                    console.log('Please select a "Location" before clicking the Refresh button.');
                                }
                                else if (!projectTypeId) {
                                    alert('Please select a "Project Type" before clicking the Refresh button.');
                                    console.log('Please select a "Project Type" before clicking the Refresh button.');
                                }
                                else {
                                    document.getElementById('spanRaci').innerHTML = 'Loading...';
                                    $.ajax({
                                        url: operationUriPrefix + "api/eCarApi/" + "GetRaci?orgId=" + orgId + "&projectTypeId=" + projectTypeId + "&carId=" + gCarId,
                                        dataType: "json",
                                        success: function (result) {
                                            try {
                                                console.log('eCarApi: ' + JSON.stringify(result));
                                                var car = JSON.parse(result);

                                                // Set the selected location.
                                                $("#raci-location").val(orgId);
                                                $("#raci-location").selectmenu("refresh");
                                                // Set the selected project type.
                                                $("#raci-projectType").val(projectTypeId);
                                                $("#raci-projectType").selectmenu("refresh");

                                                var html = '';
                                                html += '<table border="1" style="border-color:orange;">';
                                                html += '  <tr>';
                                                html += '    <td>Step</td>';
                                                html += '    <td>RoleId</td>';
                                                html += '    <td>RoleName</td>';
                                                html += '    <td>RoleCategory</td>';
                                                html += '    <td>Task</td>';
                                                html += '    <td>Participants</td>';
                                                html += '    <td>CurStatus</td>';
                                                html += '    <td>AssignDate</td>';
                                                html += '    <td>CompletionDate</td>';
                                                html += '    <td>Timeout</td>';
                                                html += '    <td>Cond</td>';
                                                html += '  </tr>';

                                                // Iterate through all of the steps.
                                                for (var i = 0; i < car.RaciSteps.length; i++) {

                                                    var cellColor = 'white';
                                                    if (car.RaciSteps[i].StepName === 'Admin') {
                                                        cellColor = 'lightblue';
                                                    } else if (car.RaciSteps[i].StepName === 'Collaboration') {
                                                        cellColor = 'lightgreen';
                                                    } else if (car.RaciSteps[i].StepName === 'VPLevel') {
                                                        cellColor = 'pink';
                                                    } else if (car.RaciSteps[i].StepName === 'ExecLevel') {
                                                        cellColor = 'lightgrey';
                                                    }

                                                    // Display the header row for this step.
                                                    html += '<tr style="border-bottom-color:red;">';
                                                    var stepName = car.RaciSteps[i].StepName;
                                                    if (stepName == 'Done') {
                                                        stepName = 'Completed (Done)'; // This is what we want the Done step renamed to in the future...
                                                    }
                                                    html += '  <td colspan="11" style="font-weight:bold;padding: 10px;background-color:' + cellColor + ';" >Step: ' + stepName + '</td>';
                                                    html += '  </td>';
                                                    html += '</tr>';

                                                    // Display Inform roles.
                                                    for (var j = 0; j < car.RaciSteps[i].InformRoles.length; j++) {
                                                        if (car.RaciSteps[i].InformRoles[j].Participants.length > 0) {
                                                            html += '<tr>';
                                                            //html += '  <td style="background-color:' + cellColor + ';" >' + car.RaciSteps[i].StepName + '</td>';
                                                            html += '  <td style="background-color:' + cellColor + ';" ></td>';
                                                            if (car.RaciSteps[i].InformRoles[j].RoleId) {
                                                                html += '<td style="background-color:' + cellColor + ';" >' + car.RaciSteps[i].InformRoles[j].RoleId + '</td>';
                                                            } else {
                                                                html += '<td style="background-color:' + cellColor + ';" >' + car.RaciSteps[i].InformRoles[j].IdField + '</td>';
                                                            }
                                                            html += '<td style="background-color:' + cellColor + ';" >' + car.RaciSteps[i].InformRoles[j].RoleName + '</td>';
                                                            html += '<td>';
                                                            html += 'Inform';
                                                          // REMOVE FOR NOW - Admins should not have this #PFG //  html += '&nbsp;&nbsp;<a class="glyphicon glyphicon-pencil" onclick="alert(\'The ability to change this role category may be coming in a future version of this raci chart.\');" style="cursor:pointer;"></a>';
                                                            html += '</td >';
                                                            html += '<td></td>';
                                                            //html += '<td>' + car.RaciSteps[i].InformRoles[j].Participants[0].UserId + '</td>';
                                                            html += '<td onclick="displayHoveroverTooltipForUserName();" >';
                                                            for (var k = 0; k < car.RaciSteps[i].InformRoles[j].Participants.length; k++) {
                                                                console.log('UserName: ' + car.RaciSteps[i].InformRoles[j].Participants[k].UserName);
                                                                //html += '<span id="spanInformUserName-' + i + '-' + j + '-' + k + '" onclick="displayHoveroverTooltipForUserName(\'' + car.RaciSteps[i].InformRoles[j].Participants[k].UserId + '\', this);" style="cursor:pointer;" title="Click this username to view their details..." >';
                                                                //html += car.RaciSteps[i].InformRoles[j].Participants[k].UserName;


                                                                html += '<a id="spanInformUserName-' + i + '-' + j + '-' + k + '" style="cursor:pointer;font-weight:bold;" onclick="displayHoveroverTooltipForUserName(\'' + car.RaciSteps[i].InformRoles[j].Participants[k].UserId + '\', this);" >' + car.RaciSteps[i].InformRoles[j].Participants[k].UserName + '</a>';
                                                                // REMOVE FOR NOW - Admins should not have this #PFG //  html += '&nbsp;&nbsp;<a class="glyphicon glyphicon-pencil" onclick="alert(\'The ability to change the user for this role may be coming in a future version of this raci chart\');" style="cursor:pointer;"></a>';



                                                                html += '<div id="spanInformUserName-' + i + '-' + j + '-' + k + '-Tooltip"></div></span>';
                                                                html += '<br />';
                                                            }
                                                            html += '</td>'

                                                            html += '<td>';
                                                            for (var k = 0; k < car.RaciSteps[i].InformRoles[j].Participants.length; k++) {
                                                                html += '<span style="font-weight:bold;color:red;text-shadow: -1px -1 px 0 #ff, 1px -1px 0 #ff, -1px 1px 0 #ff, 1px 1px 0 #ff;">';
                                                                html += car.RaciSteps[i].InformRoles[j].Participants[k].CurStatus;
                                                                html += '</span>';
                                                                html += '<br />';
                                                            }
                                                            html += '</td>'

                                                            html += '<td>';
                                                            for (var k = 0; k < car.RaciSteps[i].InformRoles[j].Participants.length; k++) {
                                                                html += '<span>';
                                                                html += car.RaciSteps[i].InformRoles[j].Participants[k].AssignDate;
                                                                html += '</span>';
                                                                html += '<br />';
                                                            }
                                                            html += '</td>'

                                                            html += '<td>';
                                                            for (var k = 0; k < car.RaciSteps[i].InformRoles[j].Participants.length; k++) {
                                                                html += '<span>';
                                                                html += car.RaciSteps[i].InformRoles[j].Participants[k].CompletionDate;
                                                                html += '</span>';
                                                                html += '<br />';
                                                            }
                                                            html += '</td>'

                                                            html += '<td>';

                                                            if (car.RaciSteps[i].InformRoles[j].Timeout.length > 0) {
                                                                // This decides whether to display the timeout in minutes or days.
                                                                var timeoutMinutes = car.RaciSteps[i].InformRoles[j].Timeout;
                                                                var timeoutDays;
                                                                if (timeoutMinutes > 720) {
                                                                    var minutesInASingleDay = 1440;
                                                                    timeoutDays = timeoutMinutes / minutesInASingleDay;
                                                                }
                                                                if (timeoutDays) {
                                                                    html += timeoutDays;
                                                                    html += ' days';
                                                                } else {
                                                                    html += timeoutMinutes;
                                                                    html += ' minutes';
                                                                }
                                                            }
                                                            html += '</td>';
                                                            html += '<td>';
                                                            html += car.RaciSteps[i].InformRoles[j].Cond;
                                                            if (car.RaciSteps[i].InformRoles[j].Cond.length > 0) {
                                                                // REMOVE FOR NOW - Admins should not have this #PFG //  html += '&nbsp;&nbsp;<a class="glyphicon glyphicon-wrench" alt="Configure this condition..." title="Configure this condition..." onclick="alert(\'The ability to configure this condition may be coming in a future version of this raci chart.\');" style="cursor:pointer;"></a>';
                                                            }
                                                            html += '</td>';
                                                            html += '</tr>';
                                                        }
                                                    }

                                                    // Display Assign roles.
                                                    for (var j = 0; j < car.RaciSteps[i].AssignRoles.length; j++) {
                                                        if (car.RaciSteps[i].AssignRoles[j].Participants.length > 0) {
                                                            html += '<tr>';
                                                            //html += '  <td style="background-color:' + cellColor + ';" >' + car.RaciSteps[i].StepName + '</td>';
                                                            html += '  <td style="background-color:' + cellColor + ';" ></td>';
                                                            html += '<td style="background-color:' + cellColor + ';" >' + car.RaciSteps[i].AssignRoles[j].RoleId + '</td>';
                                                            html += '<td style="background-color:' + cellColor + ';" >' + car.RaciSteps[i].AssignRoles[j].RoleName + '</td>';

                                                            html += '<td>';
                                                            html += car.RaciSteps[i].AssignRoles[j].RoleCategory;
                                                            // REMOVE FOR NOW - Admins should not have this #PFG //   html += '&nbsp;&nbsp;<a class="glyphicon glyphicon-pencil" onclick="alert(\'The ability to change this role category may be coming in a future version of this raci chart.\');" style="cursor:pointer;"></a>';
                                                            html += '</td>';

                                                            html += '<td>';
                                                            html += car.RaciSteps[i].AssignRoles[j].Title;
                                                            if (car.RaciSteps[i].AssignRoles[j].Title.toLowerCase().indexOf('checklist') > -1) {
                                                                // REMOVE FOR NOW - Admins should not have this #PFG //    html += '&nbsp;&nbsp;<a class="glyphicon glyphicon-check" alt="View this checklist..." title="View this checklist..." onclick="alert(\'The ability to view this checklist may be coming in a future version of this raci chart\');" style="cursor:pointer;"></a>';
                                                            }
                                                            html += '</td>';
                                                            html += '<td>';

                                                            for (var k = 0; k < car.RaciSteps[i].AssignRoles[j].Participants.length; k++) {
                                                                console.log('UserName: ' + car.RaciSteps[i].AssignRoles[j].Participants[k].UserName);
                                                                //html += '<span id="spanAssignUserName-' + i + '-' + j + '-' + k + '" onclick="displayHoveroverTooltipForUserName(\'' + car.RaciSteps[i].AssignRoles[j].Participants[k].UserId + '\', this);" style="cursor:pointer;" title="Click this username to view their details..." >';
                                                                //html += car.RaciSteps[i].AssignRoles[j].Participants[k].UserName;


                                                                html += '<a id="spanAssignUserName-' + i + '-' + j + '-' + k + '" style="cursor:pointer;font-weight:bold;" onclick="displayHoveroverTooltipForUserName(\'' + car.RaciSteps[i].AssignRoles[j].Participants[k].UserId + '\', this);" >' + car.RaciSteps[i].AssignRoles[j].Participants[k].UserName + '</a>';
                                                                // REMOVE FOR NOW - Admins should not have this #PFG //   html += '&nbsp;&nbsp;<a class="glyphicon glyphicon-pencil" onclick="alert(\'The ability to change the user for this role may be coming in a future version of this raci chart\');" style="cursor:pointer;"></a>';


                                                                html += '<div id="spanAssignUserName-' + i + '-' + j + '-' + k + '-Tooltip"></div></span>';
                                                                html += '<br />';
                                                            }
                                                            html += '</td>';

                                                            html += '<td>';
                                                            for (var k = 0; k < car.RaciSteps[i].AssignRoles[j].Participants.length; k++) {
                                                                html += '<span style="font-weight:bold;color:red;text-shadow: -1px -1 px 0 #ff, 1px -1px 0 #ff, -1px 1px 0 #ff, 1px 1px 0 #ff;">';
                                                                html += car.RaciSteps[i].AssignRoles[j].Participants[k].CurStatus;
                                                                if (car.RaciSteps[i].AssignRoles[j].Participants[k].CurStatus === 'Done' && car.RaciSteps[i].AssignRoles[j].RoleCategory === 'Approver') { // && car.RaciSteps[i].StepName == 'ACTIVE STEP') {
                                                                    if (gUserHasRole_SUPER == 'true') {// #PFG - not for Admins} || gUserHasRole_ADMIN == 'true') {
                                                                        html += '<br /><a style="cursor:pointer;" onclick="PerformWorkflowAssignmentReversalFromDoneToAssigned(\'' + car.RaciSteps[i].AssignRoles[j].Participants[k].WFAssignId + '\');">Revert to "Assigned"</a>';
                                                                    }
                                                                }
                                                                html += '</span>';
                                                                html += '<br />';
                                                            }
                                                            html += '</td>';

                                                            html += '<td>';
                                                            for (var k = 0; k < car.RaciSteps[i].AssignRoles[j].Participants.length; k++) {
                                                                html += '<span>';
                                                                html += car.RaciSteps[i].AssignRoles[j].Participants[k].AssignDate;
                                                                html += '</span>';
                                                                html += '<br />';
                                                            }
                                                            html += '</td>';

                                                            html += '<td>';
                                                            for (var k = 0; k < car.RaciSteps[i].AssignRoles[j].Participants.length; k++) {
                                                                html += '<span>';
                                                                html += car.RaciSteps[i].AssignRoles[j].Participants[k].CompletionDate;
                                                                html += '</span>';
                                                                html += '<br />';
                                                            }
                                                            html += '</td>';

                                                            html += '<td>';

                                                            if (car.RaciSteps[i].AssignRoles[j].Timeout.length > 0) {
                                                                // This decides whether to display the timeout in minutes or days.
                                                                var timeoutMinutes = car.RaciSteps[i].AssignRoles[j].Timeout;
                                                                var timeoutDays;
                                                                if (timeoutMinutes > 720) {
                                                                    var minutesInASingleDay = 1440;
                                                                    timeoutDays = timeoutMinutes / minutesInASingleDay;;
                                                                }
                                                                if (timeoutDays) {
                                                                    html += timeoutDays;
                                                                    html += ' days';
                                                                } else {
                                                                    html += timeoutMinutes;
                                                                    html += ' minutes';
                                                                }
                                                            }

                                                            html += '</td>';
                                                            html += '<td>';
                                                            html += car.RaciSteps[i].AssignRoles[j].Cond;

                                                            if (car.RaciSteps[i].AssignRoles[j].Cond.length > 0) {
                                                                // REMOVE FOR NOW - Admins should not have this #PFG //   html += '&nbsp;&nbsp;<a class="glyphicon glyphicon-wrench" alt="Configure this condition..." title="Configure this condition..." onclick="alert(\'The ability to configure this condition may be coming in a future version of this raci chart.\');" style="cursor:pointer;"></a>';
                                                            }

                                                            html += '</td>';
                                                            html += '</tr>';
                                                        }
                                                    }
                                                    html += '</tr>';
                                                }
                                                html += '</table>';
                                                document.getElementById('spanRaci').innerHTML = html;
                                            }
                                            catch (e) {
                                                console.log('Exception in CarForm3.aspx.populateRaciTab(): GET eCarApi/id: ' + e.message + ', ' + e.stack);
                                            }
                                        },
                                        error: function (result) {
                                            document.getElementById('CARForm-Title').innerHTML = 'ERROR: GET api/eCarApi: ' + JSON.stringify(result);
                                        },
                                        timeout: 25000 // This one may take a bit longer to come back.
                                    });
                                }
                            },
                            function () {
                                console.log('Exception in CarForm3.aspx.populateRaciTab(): Failure in setting projectReasonEditor options.');
                            }
                        ).done(function () { lpSpinner.Hide(); }); //Turn off spinner
                    deferred.resolve();
                }
            }
            catch (e) {
                console.log('Exception in CarForm3.aspx.populateRaciTab(): ' + e.message + ', ' + e.stack);
            }
        };

        function displayHoveroverTooltipForUserName(userId, elem) {
            // Displays the users Email, Role Assignments, Contact info, and work list.
            try {
                if (elem) {
                    console.log('In Raci.apsx.displayHoveroverTooltipForUserName(' + userId + ', ' + elem.id + ').');
                    var tpElem = document.getElementById(elem.id + '-Tooltip');
                    $.ajax({
                        url: operationUriPrefix + "odata/CARUsers?$filter=UserId eq " + userId,
                        dataType: "json"
                    }).done(function (result) {
                        try {
                            var user = result.value[0];
                            var html = '';
                            html += user.UserEMail + ' (UserId:' + user.UserId + ')';
                            html += '<br /><br />';
                            $.ajax({
                                url: operationUriPrefix + "odata/vUserRoles?$filter=UserId eq " + userId,
                                dataType: "json"
                            }).done(function (result) {
                                try {
                                    var userroles = result.value;
                                    lpSpinner.SetText('Retrieving data for ' + user.FirstName + ' ' + user.LastName + '...');
                                    //lpSpinner.Show();
                                    html += '<table border=1>';
                                    html += '<tr><td>USER ROLES for ' + user.FirstName + ' ' + user.LastName + ':</td></tr>';
                                    for (var i = 0; i < userroles.length; i++) {
                                        html += '<tr><td>';
                                        html += userroles[i].OrgName + ': ' + userroles[i].RoleName;
                                        html += '<br />';
                                        html += '</td></tr>';
                                    }
                                    html += '</table>';
                                    html += '<br />';
                                    $.ajax({
                                        url: operationUriPrefix + "odata/vWorklists?$filter=UserId eq " + userId + " and CurStatus ne 'Done'",
                                        dataType: "json"
                                    }).done(function (result) {
                                        try {
                                            var userroles = result.value;
                                            html += '<table border=1>';
                                            html += '<tr><td>WORK LIST for ' + user.FirstName + ' ' + user.LastName + ':</td></tr>';
                                            for (var i = 0; i < userroles.length; i++) {
                                                html += '<tr><td>';
                                                html += userroles[i].AssignDate + ': ' + userroles[i].ProjectTitle + ': ' + userroles[i].Title;
                                                html += '<br />';
                                                html += '</td></tr>';
                                            }
                                            html += '</table>';
                                            html += '<br />';
                                            $.ajax({
                                                url: operationUriPrefix + "odata/vMailHists?$filter=ToAddr eq '" + user.UserEMail + "'",
                                                dataType: "json"
                                            }).done(function (result) {
                                                try {
                                                    var userroles = result.value;
                                                    html += '<table border=1>';
                                                    html += '<tr><td>Last 10 (or less) EMAILS SENT to ' + user.FirstName + ' ' + user.LastName + ':</td></tr>';
                                                    //for (var i = 0; i < userroles.length; i++) { // This displays all of the emails. Keep this here in case we need it in the future.
                                                    for (var i = 0; i < userroles.length && i < 10; i++) {
                                                        html += '<tr><td>';
                                                        html += userroles[i].TimeStmp + ': ' + userroles[i].ProjectTitle + ': ' + userroles[i].Subj;
                                                        html += '<br />';
                                                        html += '</td></tr>';
                                                    }
                                                    html += '</table>';
                                                    html += '<br />';



                                                    html += '<table border=1>';
                                                    html += '<tr><td>LATEST COMPLETED TASKS/ASSIGNMENTS by ' + user.FirstName + ' ' + user.LastName + ':</td></tr>';
                                                    html += '<tr><td>[this functionality is incomplete]</td></tr>';
                                                    html += '</table>';
                                                    html += '<br />';

                                                    html += '<table border=1>';
                                                    html += '<tr><td>WHAT ELSE SHOULD WE SHOW HERE? for ' + user.FirstName + ' ' + user.LastName + ':</td></tr>';
                                                    html += '<tr><td>[let us know!]</td></tr>';
                                                    html += '</table>';
                                                    html += '<br />';

                                                    tpElem.innerHTML = html;
                                                    //lpSpinner.Hide();
                                                } catch (e) {
                                                    //lpSpinner.Hide();
                                                    console.log('Exception in displayHoveroverTooltipForUserName: ' + e.message + ', ' + e.stack);
                                                }
                                            });
                                        } catch (e) {
                                            //lpSpinner.Hide();
                                            console.log('Exception in displayHoveroverTooltipForUserName: ' + e.message + ', ' + e.stack);
                                        }
                                    });
                                } catch (e) {
                                    //lpSpinner.Hide();
                                    console.log('Exception in displayHoveroverTooltipForUserName: ' + e.message + ', ' + e.stack);
                                }
                            });
                        } catch (e) {
                            //lpSpinner.Hide();
                            console.log('Exception in displayHoveroverTooltipForUserName: ' + e.message + ', ' + e.stack);
                        }
                    });
                }
            } catch (e) {
                //lpSpinner.Hide();
                console.log('Exception in Raci.aspx.displayHoveroverTooltipForUserName(): ' + e.message + ', ' + e.stack);
            }
        }

        function hideHoveroverTooltipForUserName(elem) {
            // Displays the users Email, Role Assignments, Contact info, and work list.
            try {
                //if (elem) {
                //    console.log('In Raci.apsx.hideHoveroverTooltipForUserName(' + elem.id + ').');
                //    var tpElem = document.getElementById(elem.id + '-Tooltip');
                //    tpElem.innerHTML = '';
                //}
            } catch (e) {
                console.log('Exception in Raci.aspx.hideHoveroverTooltipForUserName(): ' + e.message + ', ' + e.stack);
            }
        }

        function populateCostSheetReadOnly() {
            try {
                console.log('In CarForm3.aspx.populateCostSheetReadOnly().');

                var costSheetItems = new DevExpress.data.CustomStore({
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;

                        $.ajax({
                            url: operationUriPrefix + "odata/CostSheets?$filter=CARId eq " + gCarId + ' and Quantity gt 0',
                            dataType: "json",
                            data: args,
                            success: function (result) {
                                //Get the Project Capital Spending total
                                //console.log('result.value: ' + JSON.stringify(result.value));
                                var costSheets = result.value;
                                var projCapitalTotal = 0;

                                if (costSheets.length > 1) {
                                    for (var i = 0; i < costSheets.length; i++) {
                                        projCapitalTotal += costSheets[i].Capital;
                                    }

                                    TotalProjectedCapitalSpending = projCapitalTotal;
                                }
                                deferred.resolve(result.value, {});
                            },
                            error: function (data) {
                                var error = JSON.parse(data.responseText)["odata.error"];
                                var errormsg = 'Exception in CarForm3.aspx.populateCostSheetReadOnly().costSheetItems.CustomStore.load(): ' + error.message.value;
                                if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                deferred.reject("Data Loading Error : " + errormsg);
                            },
                            timeout: 60000
                        });
                        return deferred.promise();
                    }
                });

                var costSheetCategories = [];
                costSheetCategories.push({ "Value": "X", "Text": "None" });
                costSheetCategories.push({ "Value": "B", "Text": "Buildings" });
                costSheetCategories.push({ "Value": "E", "Text": "Equipment" });
                costSheetCategories.push({ "Value": "C", "Text": "Computers" });
                costSheetCategories.push({ "Value": "S", "Text": "Services" });

                $("#jsGridCostSheet").dxDataGrid({
                    dataSource: {
                        store: costSheetItems
                    },
                    loadPanel: {
                        enabled: false
                    },
                    width: '100%',
                    cacheEnabled: true,
                    editing: {
                        mode: "row",
                        allowUpdating: false,
                        allowDeleting: false,
                        allowAdding: false
                    },
                    paging: { enabled: false },
                    remoteOperations: false,
                    searchPanel: {
                        visible: false
                    },
                    allowColumnReordering: false,
                    allowColumnResizing: false,
                    rowAlternationEnabled: false,
                    showBorders: true,
                    filterRow: { visible: false },
                    columns: [
                        {
                            dataField: "Quantity",
                            caption: "Quantity",
                            width: '10%'
                        },
                        {
                            dataField: "Category",
                            dataType: "string",
                            caption: "Category",
                            width: '10%',
                            lookup: {
                                dataSource: costSheetCategories,
                                displayExpr: "Text",
                                valueExpr: "Value"
                            }
                        },
                        {
                            dataField: "Descr",
                            dataType: "string",
                            caption: "Description",
                            width: '25%'
                        },
                        {
                            dataField: "Capital",
                            caption: "Capital",
                            width: '10%',
                            format: { type: "currency", precision: 0 }
                        },
                        {
                            dataField: "Expense",
                            caption: "Expense",
                            width: '10%',
                            format: { type: "currency", precision: 0 }
                        },
                        {
                            dataField: "OperLease",
                            width: '10%',
                            format: { type: "currency", precision: 0 }
                        },
                        {
                            dataField: "Total",
                            caption: "Total",
                            width: '10%',
                            format: { type: "currency", precision: 0 }
                        },
                        {
                            dataField: "Vendor",
                            dataType: "string",
                            caption: "Vendor",
                            width: '15%'
                        }
                    ],
                    summary: {
                        totalItems: [{
                            column: "Quantity",
                            alignment: "left",
                            displayFormat: "Total"
                        },
                        {
                            column: "Capital",
                            summaryType: "sum",
                            alignment: "right",
                            valueFormat: "currency",
                            displayFormat: "{0}"
                        },
                        {
                            column: "Expense",
                            summaryType: "sum",
                            alignment: "right",
                            valueFormat: "currency",
                            displayFormat: "{0}"
                        },
                        {
                            column: "OperLease",
                            summaryType: "sum",
                            alignment: "right",
                            valueFormat: "currency",
                            displayFormat: "{0}"
                        },
                        {
                            column: "Total",
                            summaryType: "sum",
                            alignment: "right",
                            valueFormat: "currency",
                            displayFormat: "{0}"
                        }]
                    },
                    onCellPrepared: function (e) {
                        if (e.rowType == "totalFooter") {
                            e.cellElement.css({ "font-style": "italic", "font-weight": "bold" });
                        }
                    }
                });
            } catch (e) {
                console.log('Exception in CarForm3.aspx.populateCostSheetReadOnly(): ' + e.message + ', ' + e.stack);
            }
        };

        function populateForecastParameters() {
            try {
                console.log('In CarForm3.aspx.populateForecastParameters().');
                var amountLeft = 0;
                var totalProjectedCapital = 0;
                var totalAmountForecast = 0;

                var deferred = $.Deferred();
                deferred
                    .then(
                        function () {
                            $.ajax({
                                url: operationUriPrefix + "odata/vSpendForecasts?$filter=CARId eq " + gCarId,
                                dataType: "json",
                                success: function (result) {
                                    var spendForecasts = result.value;
                                    console.log('spendForecasts.value: ' + JSON.stringify(spendForecasts));

                                    $.ajax({
                                        url: operationUriPrefix + "odata/CostSheets?$filter=CARId eq " + gCarId,
                                        dataType: "json",
                                        success: function (result) {
                                            var costSheets = result.value;
                                            console.log('costSheets.value: ' + JSON.stringify(costSheets));

                                            //Calculate Amount Forecast
                                            if (spendForecasts.length > 0) {
                                                for (var i = 0; i < spendForecasts.length; i++) {
                                                    totalAmountForecast += Number(spendForecasts[i].Spend);
                                                }
                                                TotalAmountForecast = totalAmountForecast;
                                            }
                                            generateLabel('amountForecast', commaSeparateNumber(totalAmountForecast));


                                            //Calculate Projected Capital
                                            if (costSheets.length > 0) {
                                                for (var i = 0; i < costSheets.length; i++) {
                                                    if (costSheets[i].Quantity == 0) {
                                                        if (costSheets[i].Category != 1)
                                                            totalProjectedCapital += Number(costSheets[i].Capital);
                                                    }
                                                    else {
                                                        totalProjectedCapital += Number(costSheets[i].Quantity) * Number(costSheets[i].Capital);
                                                    }
                                                }
                                                TotalProjectedCapitalSpending = totalProjectedCapital;
                                            }

                                            generateLabel('projectedCapitalSpending', commaSeparateNumber(totalProjectedCapital));


                                            //Calculate Amount Left to Forecast
                                            amountLeft = Number(totalProjectedCapital) - Number(totalAmountForecast);
                                            generateLabel('amountLeftToForecast', commaSeparateNumber(amountLeft));

                                        },
                                        error: function (data) {
                                            var error = JSON.parse(data.responseText)["odata.error"];
                                            var errormsg = 'Exception in CarForm3.aspx.populateForecastParameters():1: ' + error.message.value;
                                            if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                            if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                            deferred.reject("Data Loading Error : " + errormsg);
                                        }
                                    });
                                },
                                error: function (data) {
                                    var error = JSON.parse(data.responseText)["odata.error"];
                                    var errormsg = 'Exception in CarForm3.aspx.populateForecastParameters():2: ' + error.message.value;
                                    if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                    if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                    deferred.reject("Data Loading Error : " + errormsg);
                                }
                            });
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateForecastParameters():3: Failure in populating parameters.');
                        }
                    );
                deferred.resolve();

            } catch (e) {
                console.log('Exception in CarForm3.aspx.populateForecastParameters():4: ' + e.message + ', ' + e.stack);
            }
        };

        function UpdateFixedCostRows() {
            try {
                console.log('In CarForm3.aspx.UpdateFixedCostRows().');

                var deferred = $.Deferred();
                deferred
                    .then(
                        function () {
                            $.ajax({
                                url: operationUriPrefix + "odata/CostSheets?$filter=CARId eq " + gCarId + ' and Quantity gt 0',
                                dataType: "json",
                                success: function (result) {
                                    var costSheets = result.value;
                                    console.log('costSheets.value: ' + JSON.stringify(costSheets));

                                    var totalCapital = 0;
                                    var totalExpense = 0;
                                    var totalOperLease = 0;

                                    //Calculate Projected Capital
                                    if (costSheets.length > 0) {
                                        for (var i = 0; i < costSheets.length; i++) {
                                            totalCapital += Number(costSheets[i].Quantity) * Number(costSheets[i].Capital);
                                            totalExpense += Number(costSheets[i].Quantity) * Number(costSheets[i].Expense);
                                            totalOperLease += Number(costSheets[i].Quantity) * Number(costSheets[i].OperLease);
                                        }
                                    }

                                    var dataGrid = $("#jsGridFixedCost").dxDataGrid("instance");
                                    var rows = dataGrid.getVisibleRows();
                                    if (rows.length > 0)
                                    {
                                        for (var index = 0; index < rows.length; ++index)
                                        {
                                            var curCapital = 0, curExpense = 0, curOperLease = 0, curTotal = 0;                                          
                                            var curCateg = Number(dataGrid.cellValue(index, "Category"));

                                            /// Set the Fixed Cost Capital
                                            curCapital = (totalCapital * Number(dataGrid.cellValue(index, "Percentage"))) / (100);
                                            dataGrid.cellValue(index, "Capital", curCapital);

                                            /// Set Expense and Operating Lease based on Category
                                            switch (curCateg) 
                                            {
                                                case 1:    // Contingency
                                                    curExpense = (totalExpense * Number(dataGrid.cellValue(index, "Percentage"))) / (100);
                                                    dataGrid.cellValue(index, "Expense", curExpense);
                                                    dataGrid.cellValue(index, "OperLease", curOperLease);
                                                    break;
                                                case 5:    // Capitalized Interest
                                                    dataGrid.cellValue(index, "Expense", curExpense);
                                                    dataGrid.cellValue(index, "OperLease", curOperLease);
                                                    break;
                                                default:
                                                    curExpense = (totalExpense * Number(dataGrid.cellValue(index, "Percentage"))) / (100);
                                                    dataGrid.cellValue(index, "Expense", curExpense);
                                                    curOperLease = (totalOperLease * Number(dataGrid.cellValue(index, "Percentage"))) / (100);
                                                    dataGrid.cellValue(index, "OperLease", curOperLease);
                                                    break;
                                            }

                                            /// Set the Fixed Cost Total
                                            curTotal = (curCapital + curExpense + curOperLease);
                                            dataGrid.cellValue(index, "Total", curTotal);
                                        }

                                        dataGrid.saveEditData()
                                            .done(function () {
                                                console.log("in CarForm3.aspx.UpdateFixedCostRows(): Successful save!");
                                                $("#jsGridSummaryCost").dxDataGrid("instance").saveEditData();
                                                populateForecastParameters();   //update the spend forecast parameters
                                            })
                                            .fail(function (error) {
                                                console.log("in CarForm3.aspx.UpdateFixedCostRows(): Unsuccessful save!");
                                            });
                                    }
                                },
                                error: function (data) {
                                    var error = JSON.parse(data.responseText)["odata.error"];
                                    var errormsg = 'Exception in CarForm3.aspx.UpdateFixedCostRows():1: ' + error.message.value;
                                    if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                    if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                    deferred.reject("Data Loading Error : " + errormsg);
                                }
                            });
                        },
                        function () {
                            console.log('In CarForm3.aspx.UpdateFixedCostRows():2: Failure in populating parameters.');
                        }
                    );
                deferred.resolve();
            }
            catch (e) {
                console.log('Exception in CarForm3.aspx.UpdateFixedCostRows():3: ' + e.message + ', ' + e.stack);
            }
        };

        function refreshFixedCostTotals() {
            try {
                console.log('In CarForm3.aspx.refreshFixedCostTotals().');
                var projectArray = [];
                var forecastArray = [];
                var fixedCostsArray = [];

                var deferred = $.Deferred();
                deferred
                    .then(
                        function () {
                            $.ajax({
                                url: operationUriPrefix + "odata/CostSheets?$filter=CARId eq " + gCarId + ' and Quantity gt 0',
                                dataType: "json",
                                success: function (result) {
                                    var costSheets = result.value;
                                    console.log('costSheets.value1: ' + JSON.stringify(costSheets));

                                    $.ajax({
                                        url: operationUriPrefix + "odata/CostSheets?$filter=CARId eq " + gCarId + ' and Quantity eq 0',
                                        dataType: "json",
                                        success: function (result) {
                                            var fixedCosts = result.value;
                                            console.log('fixedCosts.value1: ' + JSON.stringify(fixedCosts));

                                            //Calculate Cost Sheet totals
                                            var costCapital = 0;
                                            var costExpense = 0;
                                            var costOperLease = 0;
                                            if (costSheets.length > 0) {
                                                for (var i = 0; i < costSheets.length; i++)
                                                {
                                                    costCapital += Number(costSheets[i].Quantity) * Number(costSheets[i].Capital);
                                                    costExpense += Number(costSheets[i].Quantity) * Number(costSheets[i].Expense);
                                                    costOperLease += Number(costSheets[i].Quantity) * Number(costSheets[i].OperLease);
                                                }
                                            }


                                            //Calculate Fixed Costs array
                                            var fixedCapital = 0;
                                            var fixedExpense = 0;
                                            var fixedOperLease = 0;
                                            if (fixedCosts.length > 0)
                                            {
                                                for (var i = 0; i < fixedCosts.length; i++)
                                                {
                                                    fixedCapital += Number(fixedCosts[i].Capital);
                                                    fixedExpense += Number(fixedCosts[i].Expense);
                                                    fixedOperLease += Number(fixedCosts[i].OperLease);
                                                }
                                            }

                                            fixedCostsArray = {
                                                "Title": "Fixed Costs Total",
                                                "Capital": fixedCapital,
                                                "Expense": fixedExpense,
                                                "OperLease": fixedOperLease,
                                                "Total": fixedCapital + fixedExpense + fixedOperLease
                                            };


                                            //Calculate Forecast array
                                            var forecastCapital = costCapital;
                                            var forecastExpense = 0;
                                            var forecastOperLease = 0;

                                            //Check for non-contingency fixed costs
                                            if (fixedCosts.length > 0) {
                                                for (var i = 0; i < fixedCosts.length; i++) {
                                                    if (fixedCosts[i].Category != 1)
                                                        forecastCapital += Number(fixedCosts[i].Capital);
                                                }
                                            }

                                            forecastArray = {
                                                "Title": "Forecast Total",
                                                "Capital": forecastCapital,
                                                "Expense": forecastExpense,
                                                "OperLease": forecastOperLease,
                                                "Total": forecastCapital + forecastExpense + forecastOperLease
                                            };


                                            //Calculate Project array //#PFG-FIX 
                                            var projCapital = Number(costCapital) + Number(fixedCostsArray.Capital);
                                            var projExpense = Number(costExpense) + Number(fixedCostsArray.Expense);
                                            var projOperLease = Number(costOperLease) + Number(fixedCostsArray.OperLease);


                                            projectArray = {
                                                "Title": "Project Total",
                                                "Capital": projCapital,
                                                "Expense": projExpense,
                                                "OperLease": projOperLease,
                                                "Total": projCapital + projExpense + projOperLease
                                            };


                                            var costSheetFullSummary = [];
                                            costSheetFullSummary.push(fixedCostsArray);
                                            costSheetFullSummary.push(projectArray);
                                            costSheetFullSummary.push(forecastArray);

                                            $("#jsGridSummaryCost").dxDataGrid({
                                                dataSource: {
                                                    store: costSheetFullSummary
                                                },
                                                loadPanel: {
                                                    enabled: false
                                                },
                                                width: '100%',
                                                editing: {
                                                    mode: "row",
                                                    allowUpdating: true,
                                                    allowDeleting: true,
                                                    allowAdding: false
                                                },
                                                paging: { enabled: false },
                                                showColumnHeaders: false,
                                                allowColumnReordering: false,
                                                allowColumnResizing: false,
                                                remoteOperations: false,
                                                searchPanel: { visible: false },
                                                rowAlternationEnabled: false,
                                                showBorders: true,
                                                filterRow: { visible: false },
                                                columns: [
                                                    {
                                                        dataField: "Title",
                                                        dataType: "string",
                                                        caption: "Title"
                                                    },
                                                    {
                                                        dataField: "Capital",
                                                        caption: "Capital",
                                                        format: { type: "currency", precision: 0 }
                                                    },
                                                    {
                                                        dataField: "Expense",
                                                        caption: "Expense",
                                                        format: { type: "currency", precision: 0 }
                                                    },
                                                    {
                                                        dataField: "OperLease",
                                                        caption: "Operating Lease",
                                                        format: { type: "currency", precision: 0 }
                                                    },
                                                    {
                                                        dataField: "Total",
                                                        caption: "Total",
                                                        format: { type: "currency", precision: 0 }
                                                    },
                                                    {
                                                        type: "buttons",
                                                        buttons: [] // The Edit & Delete buttons are hidden
                                                        //buttons: ["edit"] // The Delete button is hidden
                                                    }
                                                ],
                                                customizeColumns: function (columns) {
                                                    // Make columns visible, set widths, etc.
                                                    $.each(columns, function (_, column) 
                                                    {
                                                        if (column.dataField == 'Title') {
                                                            column.width = '30%';
                                                        }
                                                        else if (column.dataField == 'Capital') {
                                                            column.width = '15%';
                                                        }
                                                        else if (column.dataField == 'Expense') {
                                                            column.width = '15%';
                                                        }
                                                        else if (column.dataField == 'OperLease') {
                                                            column.width = '15%';
                                                        }
                                                        else if (column.dataField == 'Total') {
                                                            column.width = '15%';
                                                        }
                                                        else
                                                        { 
                                                            column.width = '10%';
                                                        }
                                                    });
                                                },
                                                onCellPrepared: function (e) {
                                                    if (e.rowType === "data") {
                                                        e.cellElement.css({ "font-style": "italic", "font-weight": "bold" });
                                                    }
                                                }
                                            });
                                        },
                                        error: function (data) {
                                            var error = JSON.parse(data.responseText)["odata.error"];
                                            var errormsg = 'Exception in CarForm3.aspx.refreshFixedCosts():1: ' + error.message.value;
                                            if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                            if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                            deferred.reject("Data Loading Error : " + errormsg);
                                        }
                                    });
                                },
                                error: function (data) {
                                    var error = JSON.parse(data.responseText)["odata.error"];
                                    var errormsg = 'Exception in CarForm3.aspx.refreshFixedCosts():1: ' + error.message.value;
                                    if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                    if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                    deferred.reject("Data Loading Error : " + errormsg);
                                }
                            });
                        },
                        function () {
                            console.log('In CarForm3.aspx.refreshFixedCosts():2: Failure in populating parameters.');
                        }
                    );
                deferred.resolve();

            } catch (e) {
                console.log('Exception in CarForm3.aspx.refreshFixedCosts():3: ' + e.message + ', ' + e.stack);
            }
        };

        function populateCostSheetNotReadOnly() {
            try
            {
                console.log('In CarForm3.aspx.populateCostSheetNotReadOnly().');

                var costSheetItems = new DevExpress.data.CustomStore({
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;
                        $.ajax({
                            url: operationUriPrefix + "odata/CostSheets?$filter=CARId eq " + gCarId + ' and Quantity gt 0',
                            dataType: "json",
                            data: args,
                            success: function (result) {
                                //Get the Project Capital Spending total
                                //console.log('result.value: ' + JSON.stringify(result.value));
                                var costSheets = result.value;

                                var projCapitalTotal = 0;
                                if (costSheets.length > 1)
                                {
                                    for (var i = 0; i < costSheets.length; i++)
                                    {
                                        projCapitalTotal += costSheets[i].Capital;
                                    }

                                    TotalProjectedCapitalSpending = projCapitalTotal;
                                }
                                deferred.resolve(result.value, {});
                            },
                            error: function (data) {
                                var error = JSON.parse(data.responseText)["odata.error"];
                                var errormsg = 'Exception in CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.CustomStore.load(): ' + error.message.value;
                                if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                deferred.reject("Data Loading Error : " + errormsg);
                            },
                            timeout: 60000
                        });
                        return deferred.promise();
                    },
                    insert: function (values) {
                        lpSpinner.SetText('Adding to the Cost Sheet...');
                        //lpSpinner.Show();
                        console.log('In CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.insert: values: ' + JSON.stringify(values)); // eg: values: {"__KEY__":"96559962-1911-8948-e967-efd82053c790","Quantity":3,"Category":"B","Descr":"reedwqdasfda","Capital":334}
                        if (values) { // Just checking if we need to save anything.
                            var columnNames = Object.keys(values); // Get the column/field names so we can decide how to save things below...
                            console.log('Object.keys(values): columnNames: ' + columnNames);
                            // 
                            // Now we get all of the changed values for the months, and save them to the database.
                            //
                            delete values["__KEY__"]; // This removes it from values.
                            var createTime = new Date();
                            var json = { "CARId": gCarId, "CreateTime": createTime, "Ordinal": 0, "Percentage": 0, "Capital": 0, "Expense": 0, "OperLease": 0, "Total": 0 };
                            $.extend(json, values); // Merge the newly saved values back to the global CAR object, gCar so that it reflects the contents of the datbase.
                            console.log("costsheet.items.insert= " + operationUriPrefix + "odata/CostSheets");
                            console.log('In CarForm3.aspx.populateCostSheetNotReadOnly().CostSheetItems.insert: getting ready to send to DB. json: ' + JSON.stringify(json));
                            // We have it!!!! Update the database
                            //lpSpinner.Show();
                            $.ajax({
                                url: operationUriPrefix + "odata/CostSheets",
                                dataType: "json",
                                contentType: "application/json",
                                type: "Post",
                                data: JSON.stringify(json)
                            }).done(function (result2) {
                                try {
                                    console.log('In CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.insert: Successfully updated DB using (' + JSON.stringify(values) + '): result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                    $("#jsGridCostSheet").dxDataGrid("instance").refresh();
                                    $("#jsGridFixedCost").dxDataGrid("instance").refresh();
                                    populateForecastParameters();   //update the spend forecast parameters
                                    //lpSpinner.Hide();
                                }
                                catch (e) {
                                    console.log('Exception in CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.insert: ' + e.message + ', ' + e.stack);
                                    //lpSpinner.Hide();
                                }
                            }).fail(function (data) {
                                //lpSpinner.Hide();
                                var msg;
                                if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                    msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                } else {
                                    msg = JSON.stringify(data);
                                }
                                alert('Exception in CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.insert: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                console.log('Exception in CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.insert: ' + JSON.stringify(data));
                                //var error = JSON.parse(data.responseText)["odata.error"];
                            });
                        } else {
                            //lpSpinner.Hide();
                            console.log('There was nothing to save back to the database.');
                            alert('There was nothing to save back to the database.');
                        }
                    },
                    update: function (keys, values) {
                        lpSpinner.SetText('Updating the Cost Sheet...');
                        //lpSpinner.Show();
                        console.log('In CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.update: keys: ' + JSON.stringify(keys) + ', values: ' + JSON.stringify(values)); // eg: yyyyyyyyyyyyyyyyyyyyyyyyyy values: {"July 2019":7777}
                        if (keys && values) { // Just checking if we need to save anything.
                            var columnNames = Object.keys(values); // Get the column/field names so we can decide how to save things below...
                            console.log('Object.keys(values): columnNames: ' + columnNames);
                            var costSheet = keys; // The "CostSheetId" value.
                            var costSheetId = costSheet.CostSheetId;
                            // 
                            // Now we get all of the changed values for the months, and save them to the database.
                            //
                            console.log('In CarForm3.aspx.populateCostSheetNotReadOnly().CostSheetItems.update: getting ready to send to DB. costSheetId: ' + costSheetId + ', values: ' + JSON.stringify(values));
                            // We have it!!!! Update the database
                            lpSpinner.SetText('Saving...');
                            //lpSpinner.Show();
                            $.ajax({
                                url: operationUriPrefix + "odata/CostSheets(" + costSheetId + ")",
                                dataType: "json",
                                contentType: "application/json",
                                type: "Patch",
                                data: JSON.stringify(values)
                            }).done(function (result2) {
                                try {
                                    if (result2) {
                                        //lpSpinner.Hide();
                                        alert('Error saving: ' + result2 + ', ' + JSON.stringify(result2));
                                        console.log('Error saving: ' + result2 + ', ' + JSON.stringify(result2));
                                    }
                                    else {
                                        console.log('In CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.update: Successfully updated DB using (' + JSON.stringify(values) + '): result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                        $("#jsGridCostSheet").dxDataGrid("instance").refresh();
                                        $("#jsGridFixedCost").dxDataGrid("instance").refresh();
                                        populateForecastParameters();   //update the spend forecast parameters
                                        //lpSpinner.Hide();
                                    }
                                } catch (e) {
                                    //lpSpinner.Hide();
                                    console.log('Exception in CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.update: ' + e.message + ', ' + e.stack);
                                }
                            }).fail(function (data) {
                                //lpSpinner.Hide();
                                var msg;
                                if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                    msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                } else {
                                    msg = JSON.stringify(data);
                                }
                                alert('Exception in CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.update: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                console.log('Exception in CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.update: ' + JSON.stringify(data));
                                //var error = JSON.parse(data.responseText)["odata.error"];
                            });
                        } else {
                            //lpSpinner.Hide();
                            console.log('There was nothing to save back to the database.');
                        }
                    },
                    remove: function (costSheet) {
                        console.log('REMOVE: costSheetId: ' + costSheet.CostSheetId);
                        //
                        // This is where we delete from CostSheet table.
                        //
                        $.ajax({
                            url: operationUriPrefix + "odata/CostSheets(" + costSheet.CostSheetId + ")",
                            dataType: "json",
                            contentType: "application/json",
                            type: "Delete"
                        }).done(function (result2) {
                            try {
                                if (result2) {
                                    //lpSpinner.Hide();
                                    alert('Error deleting: ' + result2 + ', ' + JSON.stringify(result2));
                                }
                                else {
                                    console.log('In CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.delete: Successfully deleted from DB. result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                    $("#jsGridCostSheet").dxDataGrid("instance").refresh();
                                    $("#jsGridFixedCost").dxDataGrid("instance").refresh();
                                    populateForecastParameters();   //update the spend forecast parameters
                                    //lpSpinner.Hide();
                                }
                            }
                            catch (e) {
                                console.log('Exception in CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.delete: ' + e.message + ', ' + e.stack);
                                //lpSpinner.Hide();
                            }
                        }).fail(function (data) {
                            //lpSpinner.Hide();
                            var msg;
                            if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                            }
                            else {
                                msg = JSON.stringify(data);
                            }
                            alert('Exception in CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.delete: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                            console.log('Exception in CarForm3.aspx.populateCostSheetNotReadOnly().costSheetItems.delete: ' + JSON.stringify(data));
                            //var error = JSON.parse(data.responseText)["odata.error"];
                        });
                    }
                });


                var costSheetCategories = [];
                costSheetCategories.push({ "Value": "X", "Text": "None" });
                costSheetCategories.push({ "Value": "B", "Text": "Buildings" });
                costSheetCategories.push({ "Value": "E", "Text": "Equipment" });
                costSheetCategories.push({ "Value": "C", "Text": "Computers" });
                costSheetCategories.push({ "Value": "S", "Text": "Services" });

                $("#jsGridCostSheet").dxDataGrid({
                    dataSource: {
                        store: costSheetItems
                    },
                    loadPanel: {
                        enabled: false
                    },
                    width: '100%',
                    cacheEnabled: true,
                    editing: {
                        mode: "row",
                        allowUpdating: true,
                        allowDeleting: true,
                        allowAdding: true
                    },
                    paging: { enabled: false },
                    remoteOperations: false,
                    searchPanel: {
                        visible: false
                    },
                    allowColumnReordering: false,
                    allowColumnResizing: false,
                    rowAlternationEnabled: false,
                    showBorders: true,
                    filterRow: { visible: false },
                    columns: [
                        {
                            dataField: "Quantity",
                            width: '10%',
                            validationRules: [{ type: "required", message: "Quantity is required." }]
                        },
                        {
                            dataField: "Category",
                            dataType: "string",
                            width: '10%',
                            lookup: {
                                dataSource: costSheetCategories,
                                displayExpr: "Text",
                                valueExpr: "Value"
                            },
                            validationRules: [{ type: "required", message: "Category is required." }]
                        },
                        {
                            dataField: "Descr",
                            dataType: "string",
                            caption: "Description",
                            width: '25%',
                            validationRules: [{ type: "required", message: "Descr is required." }]
                        },
                        {
                            dataField: "Capital",
                            width: '10%',
                            format: { type: "currency", precision: 0 },
                        },
                        {
                            dataField: "Expense",
                            width: '10%',
                            format: { type: "currency", precision: 0 }
                        },
                        {
                            dataField: "OperLease",
                            caption: "Operating Lease",
                            width: '10%',
                            format: { type: "currency", precision: 0 }
                        },
                        {
                            dataField: "Total",
                            caption: "Total",
                            width: '10%',
                            allowEditing: false,
                            format: { type: "currency", precision: 0 }
                        },
                        {
                            dataField: "Vendor",
                            dataType: "string",
                            width: '15%'
                        }
                    ],
                    summary: {
                        totalItems: [{
                            column: "Quantity",
                            showInColumn: "Quantity",
                            displayFormat: " "
                        },
                        {
                            name: "Capital",
                            showInColumn: "Capital",
                            summaryType: "custom",
                            valueFormat: "currency",
                            displayFormat: "{0}"
                        },
                        {
                            name: "Expense",
                            showInColumn: "Expense",
                            summaryType: "custom",
                            valueFormat: "currency",
                            displayFormat: "{0}"
                        },
                        {
                            name: "OperLease",
                            showInColumn: "OperLease",
                            summaryType: "custom",
                            valueFormat: "currency",
                            displayFormat: "{0}"
                        },
                        {
                            name: "Total",
                            showInColumn: "Total",
                            summaryType: "custom",
                            valueFormat: "currency",
                            displayFormat: "{0}"
                        }],
                        calculateCustomSummary: function (options) {
                            //console.log("options.name = " + options.name);
                            if (options.name == "Capital") {
                                //console.log("options.summaryProcess = " + options.summaryProcess);
                                switch (options.summaryProcess) {
                                    case "start":
                                        options.totalValue = 0;
                                        break;
                                    case "calculate":
                                        options.totalValue += options.value.Quantity * options.value.Capital;
                                        break;
                                    case "finalize":
                                        options.totalValue = options.totalValue;
                                        break;
                                }
                            }
                            else if (options.name == "Expense") {
                                //console.log("options.summaryProcess = " + options.summaryProcess);
                                switch (options.summaryProcess) {
                                    case "start":
                                        options.totalValue = 0;
                                        break;
                                    case "calculate":
                                        options.totalValue += options.value.Quantity * options.value.Expense;
                                        break;
                                    case "finalize":
                                        options.totalValue = options.totalValue;
                                        break;
                                }
                            }
                            else if (options.name == "OperLease") {
                                //console.log("options.summaryProcess = " + options.summaryProcess);
                                switch (options.summaryProcess) {
                                    case "start":
                                        options.totalValue = 0;
                                        break;
                                    case "calculate":
                                        options.totalValue += options.value.Quantity * options.value.OperLease;
                                        break;
                                    case "finalize":
                                        options.totalValue = options.totalValue;
                                        break;
                                }
                            }
                            else if (options.name == "Total") {
                                //console.log("options.summaryProcess = " + options.summaryProcess);
                                switch (options.summaryProcess) {
                                    case "start":
                                        options.totalValue = 0;
                                        break;
                                    case "calculate":
                                        options.totalValue += options.value.Total;
                                        break;
                                    case "finalize":
                                        options.totalValue = options.totalValue;
                                        break;
                                }
                            }
                        },
                        recalculateWhileEditing: true
                    },
                    onKeyDown: function (e) {
                        if (e.event.keyCode == 13 || e.event.keyCode == 190 || e.event.keyCode == 110)
                        {
                            console.log("CostSheet: Enter/Decimal/Period buttons disabled.");
                            e.event.preventDefault();
                            return false;
                        }
                    },
                    onCellPrepared: function (e) {
                        if (e.rowType == "totalFooter") {
                            e.cellElement.css({ "font-style": "italic", "font-weight": "bold" });
                        }
                    },
                    onInitNewRow: function (e) {
                        //alert("onInitNewRow");
                        e.data.Quantity = "1";
                        e.data.Capital = "0";
                        e.data.Expense = "0";
                        e.data.OperLease = "0";
                        e.data.Total = "0";
                    },
                    onRowValidating: function (e) {
                        //alert("RowValidating");
                        //Check for the correct values before submission
                        var QuantityValue = (e.newData.Quantity) ? Number(e.newData.Quantity) : Number(e.oldData.Quantity);
                        var CapitalValue = (e.newData.Capital) ? Number(e.newData.Capital) : Number(e.oldData.Capital);
                        var ExpenseValue = (e.newData.Expense) ? Number(e.newData.Expense) : Number(e.oldData.Expense);
                        var OperLeaseValue = (e.newData.OperLease) ? Number(e.newData.OperLease) : Number(e.oldData.OperLease);
                        //Make sure to set the new Total
                        e.newData.Total = (QuantityValue) * (CapitalValue + ExpenseValue + OperLeaseValue);
                    },
                    onEditorPreparing: function (e) {
                        //alert("onEditorPreparing");
                        var component = e.component, rowIndex = e.row && e.row.rowIndex;

                        //Added fix for backspace prevention (only when there is a value)
                        if (e.parentType == "dataRow")
                        {
                            e.editorOptions.onKeyDown = function (arg)
                            {
                                var value = e.element.find("input").val();
                                if (arg.event.keyCode == 8)
                                {
                                    if (e.editorName === "dxSelectBox" || value.length < 1)
                                    {
                                        arg.event.preventDefault();
                                        arg.event.stopPropagation();
                                    }
                                }
                            }
                        }

                        var onValueChanged = e.editorOptions.onValueChanged;
                        e.editorOptions.onValueChanged = function (e) {
                            onValueChanged.call(this, e);
                            //Emulating a web service call  
                            window.setTimeout(function () {
                                var Quantity = isNaN(Number(component.cellValue(rowIndex, "Quantity"))) ? 0 : Number(component.cellValue(rowIndex, "Quantity"));
                                var Capital = isNaN(Number(component.cellValue(rowIndex, "Capital"))) ? 0 : Number(component.cellValue(rowIndex, "Capital"));
                                var Expense = isNaN(Number(component.cellValue(rowIndex, "Expense"))) ? 0 : Number(component.cellValue(rowIndex, "Expense"));
                                var OperLease = isNaN(Number(component.cellValue(rowIndex, "OperLease"))) ? 0 : Number(component.cellValue(rowIndex, "OperLease"));
                                var Total = isNaN(Quantity * (Capital + Expense + OperLease)) ? 0 : Quantity * (Capital + Expense + OperLease);

                                //Set Total value
                                component.cellValue(rowIndex, "Total", Total);
                            }, 500);
                        }
                    },
                    onContentReady: function (e) {
                        //console.log('onContentReady - fixedCostItems: ' + fixedCostItems);
                        UpdateFixedCostRows();   //Update the fixed summary datagrid
                    }

                });
            } catch (e) {
                console.log('Exception in CarForm3.aspx.populateCostSheetNotReadOnly(): ' + e.message + ', ' + e.stack);
            }
        };

        function populateFixedCostsReadOnly() {
            try
            {
                console.log('In CarForm3.aspx.populateFixedCostsReadOnly().');

                var fixedCostItems = new DevExpress.data.CustomStore({
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;
                        $.ajax({
                            url: operationUriPrefix + "odata/CostSheets?$filter=CARId eq " + gCarId + ' and Quantity eq 0',
                            dataType: "json",
                            data: args,
                            success: function (result) {
                                var fc = result.value;
                                console.log('In populateFixedCostsReadOnly().load: fc: ' + JSON.stringify(fc));
                                //delete result["Descr"]; // This removes it from values.

                                var fcCapital = 0;
                                var fcOperLease = 0;
                                var fcExpense = 0;
                                var fcTotal = 0;

                                for (var i = 0; i < fc.length; i++) {
                                    fcCapital += Number(fc[i].Capital);
                                    fcOperLease += Number(fc[i].OperLease);
                                    fcExpense += Number(fc[i].Expense);
                                    fcTotal += Number(fc[i].Total);
                                }

                                FixedCostsArray = {
                                    "Title": "Fixed Costs Total",
                                    "Capital": fcCapital,
                                    "OperLease": fcOperLease,
                                    "Expense": fcExpense,
                                    "Total": fcTotal
                                };

                                deferred.resolve(fc, {});
                            },
                            error: function (data) {
                                var error = JSON.parse(data.responseText)["odata.error"];
                                var errormsg = 'Exception in CarForm3.aspx.populateFixedCostsReadOnly().fixedCostItems.CustomStore.load(): ' + error.message.value;
                                if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                deferred.reject("Data Loading Error : " + errormsg);
                            },
                            timeout: 60000
                        });
                        return deferred.promise();
                    }
                });


                //Get the COST SHEET data
                $.ajax({
                    url: operationUriPrefix + "odata/CostSheets?$filter=CARId eq " + gCarId + ' and Quantity gt 0',
                    dataType: "json"
                }).done(function (result) {
                    var cs = result.value;
                    console.log('In populateFixedCostsReadOnly().load: cs: ' + JSON.stringify(cs));

                    var csCapital = 0;
                    var csOperLease = 0;
                    var csExpense = 0;
                    var csTotal = 0;

                    for (var i = 0; i < cs.length; i++)
                    {
                        csCapital += Number(cs[i].Capital);
                        csExpense += Number(cs[i].Expense);
                        csOperLease += Number(cs[i].OperLease);
                        csTotal += Number(cs[i].Capital);
                    }

                    ForecastArray = {
                        "Title": "Forecast Total",
                        "Capital": csCapital,
                        "OperLease": csOperLease,
                        "Expense": csExpense,
                        "Total": csTotal
                    };


                    var fixedCostCategories = [];
                    fixedCostCategories.push({ "Value": "1", "Text": "Contingency" });
                    fixedCostCategories.push({ "Value": "2", "Text": "Freight" });
                    fixedCostCategories.push({ "Value": "3", "Text": "Outside Engineering" });
                    fixedCostCategories.push({ "Value": "4", "Text": "Tax" });
                    fixedCostCategories.push({ "Value": "5", "Text": "Capitalized Interest" }); //New Fixed Cost Added!

                    $("#jsGridFixedCost").dxDataGrid({
                        dataSource: {
                            store: fixedCostItems
                        },
                        loadPanel: {
                            enabled: false
                        },
                        width: '100%',
                        cacheEnabled: true,
                        editing: {
                            mode: "row",
                            allowUpdating: false,
                            allowDeleting: false,
                            allowAdding: false
                        },
                        paging: { enabled: false },
                        remoteOperations: false,
                        searchPanel: {
                            visible: false
                        },
                        allowColumnReordering: false,
                        allowColumnResizing: false,
                        rowAlternationEnabled: false,
                        showBorders: true,
                        filterRow: { visible: false },
                        columns: [
                            {
                                dataField: "Percentage",
                                caption: "Percentage",
                                width: '10%'
                            },
                            {
                                dataField: "Category",
                                dataType: "string",
                                caption: "Category",
                                width: '10%',
                                lookup: {
                                    dataSource: fixedCostCategories,
                                    displayExpr: "Text",
                                    valueExpr: "Value"
                                }
                            },
                            {
                                dataField: "Capital",
                                caption: "Capital",
                                width: '20%',
                                format: { type: "currency", precision: 0 }
                            },
                            {
                                dataField: "Expense",
                                caption: "Expense",
                                width: '20%',
                                format: { type: "currency", precision: 0 }
                            },
                            {
                                dataField: "OperLease",
                                caption: "Operating Lease",
                                width: '20%',
                                format: { type: "currency", precision: 0 }
                            },
                            {
                                dataField: "Total",
                                caption: "Total",
                                width: '20%',
                                format: { type: "currency", precision: 0 }
                            }
                        ],
                        onCellPrepared: function (e) {
                            if (e.rowType == "totalFooter") {
                                e.cellElement.css({ "font-style": "italic", "font-weight": "bold" });
                            }
                        },
                        onContentReady: function (e) {
                            console.log('onContentReady - fixedCostItems: ' + fixedCostItems);
                            refreshFixedCostTotals();   //Update the fixed summary datagrid
                        }
                    });
                });
            }
            catch (e) {
                console.log('Exception in CarForm3.aspx.populateFixedCostsReadOnly(): ' + e.message + ', ' + e.stack);
            }
        };

        function populateFixedCostsNotReadOnly() {
            try 
            {
                console.log('In CarForm3.aspx.populateFixedCostsNotReadOnly().');
                var fixedCostItems = new DevExpress.data.CustomStore({
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;
                        $.ajax({
                            url: operationUriPrefix + "odata/CostSheets?$filter=CARId eq " + gCarId + ' and Quantity eq 0',
                            dataType: "json",
                            data: args,
                            success: function (result) {
                                var fc = result.value;
                                console.log('In populateFixedCostsNotReadOnly().load: fc: ' + JSON.stringify(fc));
                                //delete result["Descr"]; // This removes it from values.

                                var fcCapital = 0;
                                var fcOperLease = 0;
                                var fcExpense = 0;
                                var fcTotal = 0;

                                for (var i = 0; i < fc.length; i++)
                                {
                                    fcCapital += Number(fc[i].Capital);
                                    fcExpense += Number(fc[i].Expense);
                                    fcOperLease += Number(fc[i].OperLease);
                                    fcTotal += (Number(fc[i].Capital) + Number(fc[i].Expense));
                                }

                                FixedCostsArray = {
                                    "Title": "Fixed Costs Total",
                                    "Capital": fcCapital,
                                    "Expense": fcExpense,
                                    "OperLease": fcOperLease,
                                    "Total": fcTotal
                                };

                                deferred.resolve(fc, {});
                            },
                            error: function (data) {
                                var error = JSON.parse(data.responseText)["odata.error"];
                                var errormsg = 'Exception in CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.CustomStore.load(): ' + error.message.value;
                                if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                deferred.reject("Data Loading Error : " + errormsg);
                            },
                            timeout: 60000
                        });
                        return deferred.promise();
                    },
                    insert: function (values) {
                        lpSpinner.SetText('Adding to the Fixed Costs...');
                        //lpSpinner.Show();
                        console.log('In CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.insert: values: ' + JSON.stringify(values)); // eg: values: {"__KEY__":"96559962-1911-8948-e967-efd82053c790","Quantity":3,"Category":"B","Descr":"reedwqdasfda","Capital":334}
                        if (values) { // Just checking if we need to save anything.
                            var columnNames = Object.keys(values); // Get the column/field names so we can decide how to save things below...
                            console.log('Object.keys(values): columnNames: ' + columnNames);
                            // 
                            // Now we get all of the changed values for the months, and save them to the database.
                            //
                            delete values["__KEY__"]; // This removes it from values.
                            var createTime = new Date();
                            var json = { "CARId": gCarId, "CreateTime": createTime, "Ordinal": 0, "Quantity": 0, "Percentage": 0, "Capital": 0, "Expense": 0, "OperLease": 0, "Total": 0 };
                            $.extend(json, values); // Merge the newly saved values back to the global CAR object, gCar so that it reflects the contents of the datbase.

                            console.log('In CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.insert: getting ready to send to DB. json: ' + JSON.stringify(json));
                            // We have it!!!! Update the database
                            //lpSpinner.Show();
                            $.ajax({
                                url: operationUriPrefix + "odata/CostSheets",
                                dataType: "json",
                                contentType: "application/json",
                                type: "Post",
                                data: JSON.stringify(json)
                            }).done(function (result2) {
                                try {
                                    console.log('In CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.insert: Successfully updated DB using (' + JSON.stringify(values) + '): result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                    $("#jsGridFixedCost").dxDataGrid("instance").refresh();
                                    populateForecastParameters();   //update the spend forecast parameters
                                    //lpSpinner.Hide();
                                }
                                catch (e) {
                                    //lpSpinner.Hide();
                                    console.log('Exception in CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.insert: ' + e.message + ', ' + e.stack);
                                }
                            }).fail(function (data) {
                                //lpSpinner.Hide();
                                var msg;
                                if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                    msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                } else {
                                    msg = JSON.stringify(data);
                                }
                                alert('Exception in CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.insert: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                console.log('Exception in CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.insert: ' + JSON.stringify(data));
                                //var error = JSON.parse(data.responseText)["odata.error"];
                            });
                        }
                        else
                        {
                            //lpSpinner.Hide();
                            console.log('There was nothing to save back to the database.');
                            alert('There was nothing to save back to the database.');
                        }
                    },
                    update: function (keys, values) {
                        lpSpinner.SetText('Updating the Fixed Costs...');
                        //lpSpinner.Show();
                        console.log('In CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.update: keys: ' + JSON.stringify(keys) + ', values: ' + JSON.stringify(values)); // eg: yyyyyyyyyyyyyyyyyyyyyyyyyy values: {"July 2019":7777}
                        if (keys && values) { // Just checking if we need to save anything.
                            var columnNames = Object.keys(values); // Get the column/field names so we can decide how to save things below...
                            console.log('Object.keys(values): columnNames: ' + columnNames);
                            var costSheet = keys; // The "CostSheetId" value.
                            var costSheetId = costSheet.CostSheetId;
                            // 
                            // Now we get all of the changed values for the months, and save them to the database.
                            //
                            console.log('In CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.update: getting ready to send to DB. costSheetId: ' + costSheetId + ', values: ' + JSON.stringify(values));
                            // We have it!!!! Update the database
                            lpSpinner.SetText('Saving...');
                            //lpSpinner.Show();
                            $.ajax({
                                url: operationUriPrefix + "odata/CostSheets(" + costSheetId + ")",
                                dataType: "json",
                                contentType: "application/json",
                                type: "Patch",
                                data: JSON.stringify(values)
                            }).done(function (result2) {
                                try {
                                    if (result2) {
                                        //lpSpinner.Hide();
                                        alert('Error saving: ' + result2 + ', ' + JSON.stringify(result2));
                                    }
                                    else {
                                        console.log('In CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.update: Successfully updated DB using (' + JSON.stringify(values) + '): result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                        $("#jsGridFixedCost").dxDataGrid("instance").refresh();
                                        populateForecastParameters();   //update the spend forecast parameters
                                        //lpSpinner.Hide();
                                    }
                                }
                                catch (e) {
                                    //lpSpinner.Hide();
                                    console.log('Exception in CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.update: ' + e.message + ', ' + e.stack);
                                }
                            }).fail(function (data) {
                                //lpSpinner.Hide();
                                var msg;
                                if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                    msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                } else {
                                    msg = JSON.stringify(data);
                                }
                                alert('Exception in CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.update: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                console.log('Exception in CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.update: ' + JSON.stringify(data));
                                //var error = JSON.parse(data.responseText)["odata.error"];
                            });

                        } else {
                            //lpSpinner.Hide();
                            console.log('There was nothing to save back to the database.');
                        }
                    },
                    remove: function (costSheet) {
                        console.log('REMOVE: costSheetId: ' + costSheet.CostSheetId);
                        //
                        // This is where we delete from CostSheet(Fixed) table.
                        //
                        $.ajax({
                            url: operationUriPrefix + "odata/CostSheets(" + costSheet.CostSheetId + ")",
                            dataType: "json",
                            contentType: "application/json",
                            type: "Delete"
                        }).done(function (result2) {
                            try {
                                if (result2) {
                                    //lpSpinner.Hide();
                                    alert('Error deleting: ' + result2 + ', ' + JSON.stringify(result2));
                                } else {
                                    console.log('In CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.delete: Successfully deleted from DB. result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                    $("#jsGridFixedCost").dxDataGrid("instance").refresh();
                                    populateForecastParameters();   //update the spend forecast parameters
                                    //lpSpinner.Hide();
                                }
                            } catch (e) {
                                //lpSpinner.Hide();
                                console.log('Exception in CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.delete: ' + e.message + ', ' + e.stack);
                            }
                        }).fail(function (data) {
                            //lpSpinner.Hide();
                            var msg;
                            if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                            } else {
                                msg = JSON.stringify(data);
                            }
                            alert('Exception in CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.delete: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                            console.log('Exception in CarForm3.aspx.populateFixedCostsNotReadOnly().fixedCostItems.delete: ' + JSON.stringify(data));
                            //var error = JSON.parse(data.responseText)["odata.error"];
                        });
                    }
                });


                var fixedCostCategories = [];
                fixedCostCategories.push({ "Value": "1", "Text": "Contingency" });
                fixedCostCategories.push({ "Value": "2", "Text": "Freight" });
                fixedCostCategories.push({ "Value": "3", "Text": "Outside Engineering" });
                fixedCostCategories.push({ "Value": "4", "Text": "Tax" });
                fixedCostCategories.push({ "Value": "5", "Text": "Capitalized Interest" });


                //Get the COST SHEET data
                $.ajax({
                    url: operationUriPrefix + "odata/CostSheets?$filter=CARId eq " + gCarId + ' and Quantity gt 0',
                    dataType: "json"
                }).done(function (result) {
                    //console.log('result.value: ' + JSON.stringify(result.value));

                    var cs = result.value;
                    var csCapital = 0;
                    var csOperLease = 0;
                    var csExpense = 0;
                    var csTotal = 0;

                    for (var i = 0; i < cs.length; i++) {
                        csCapital += Number(cs[i].Quantity) * Number(cs[i].Capital);
                        csExpense += Number(cs[i].Quantity) * Number(cs[i].Expense);
                        csOperLease += Number(cs[i].Quantity) * Number(cs[i].OperLease);
                        csTotal += Number(cs[i].Capital);
                    }

                    ForecastArray = {
                        "Title": "Forecast Total",
                        "Capital": csCapital,
                        "OperLease": csOperLease,
                        "Expense": csExpense,
                        "Total": csTotal
                    };


                    //var costSheetCategories = [];
                    //costSheetCategories.push({ "Value": "1", "Text": "Contingency" });
                    //costSheetCategories.push({ "Value": "2", "Text": "Freight" });
                    //costSheetCategories.push({ "Value": "3", "Text": "Outside Engineering" });
                    //costSheetCategories.push({ "Value": "4", "Text": "Tax" });
                    //costSheetCategories.push({ "Value": "5", "Text": "Capitalized Interest" });


                    $("#jsGridFixedCost").dxDataGrid({
                        dataSource: {
                            store: fixedCostItems
                        },
                        loadPanel: {
                            enabled: false
                        },
                        width: '100%',
                        cacheEnabled: true,
                        editing: {
                            mode: "row",
                            allowUpdating: true,
                            allowDeleting: true,
                            allowAdding: true
                        },
                        paging: { enabled: false },
                        remoteOperations: false,
                        searchPanel: {
                            visible: false
                        },
                        allowColumnReordering: false,
                        allowColumnResizing: false,
                        rowAlternationEnabled: false,
                        showBorders: true,
                        filterRow: { visible: false },
                        columns: [
                            {
                                dataField: "Percentage",
                                width: '10%',
                                validationRules: [{ type: "required", message: "Percentage is required." }]
                            },
                            {
                                dataField: "Category",
                                dataType: "string",
                                width: '20%',
                                lookup: {
                                    dataSource: fixedCostCategories,
                                    displayExpr: "Text",
                                    valueExpr: "Value"
                                },
                                validationRules: [{ type: "required", message: "Category is required." }]
                            },
                            {
                                dataField: "Capital",
                                width: '15%',
                                allowEditing: false,
                                format: { type: "currency", precision: 0 },
                                validationRules: [{ type: "required", message: "Capital is required." }] 
                            },
                            {
                                dataField: "Expense",
                                width: '15%',
                                allowEditing: false,
                                format: { type: "currency", precision: 0 },
                                setCellValue: function (rowData, value) {
                                    this.defaultSetCellValue(rowData, value);
                                },
                                validationRules: [{ type: "required", message: "Expense is required." }]
                            },
                            {
                                dataField: "OperLease",
                                caption: "Operating Lease",
                                width: '15%',
                                allowEditing: false,
                                format: { type: "currency", precision: 0 },
                                validationRules: [{ type: "required", message: "OperLease is required." }]
                            },
                            {
                                dataField: "Total",
                                width: '15%',
                                allowEditing: false,
                                format: { type: "currency", precision: 0 }
                            },
                            {
                                type: "buttons",
                                width: '10%'
                            }
                        ],
                        onKeyDown: function (e) {
                            if (e.event.keyCode == 13 || e.event.keyCode == 190 || e.event.keyCode == 110)
                            {
                                console.log("FixedCost: Enter/Decimal/Period buttons disabled.");
                                e.event.preventDefault();
                                return false;
                            }
                        },
                        onOptionChanged: function (e) {
                            if (e.fullName == "searchPanel.text") {
                                searchChanged = true;
                            }
                            console.log('In onOptionChanged(). e.fullName: ' + e.fullName);
                        },
                        onInitNewRow: function (e) {
                            //alert("onInitNewRow");
                            //Set the default values
                            e.data.Percentage = "0";
                            e.data.Capital = Math.round(e.data.Percentage * csCapital / 100);
                            e.data.Expense = Math.round(e.data.Percentage * csExpense / 100);
                            e.data.OperLease = Math.round(e.data.Percentage * csOperLease / 100);
                            e.data.Total = e.data.Capital + e.data.Expense + e.data.OperLease;
                        },
                        onEditorPreparing: function (e) {
                            //alert("onEditorPreparing");
                            var component = e.component, rowIndex = e.row && e.row.rowIndex;

                            //Added fix for backspace prevention (only when there is a value)
                            if (e.parentType == "dataRow") {
                                e.editorOptions.onKeyDown = function (arg) {
                                    var value = e.element.find("input").val();
                                    if (arg.event.keyCode == 8) {
                                        if (e.editorName === "dxSelectBox" || value.length < 1) {
                                            arg.event.preventDefault();
                                            arg.event.stopPropagation();
                                        }
                                    }
                                }
                            }


                            var onValueChanged = e.editorOptions.onValueChanged;
                            if (e.parentType == 'dataRow' && e.dataField == 'Percentage') {
                                e.editorOptions.onValueChanged = function (e)
                                {
                                    onValueChanged.call(this, e);
                                    // Emulating a web service call  
                                    window.setTimeout(function () {
                                        var percentage = isNaN(Number(component.cellValue(rowIndex, "Percentage"))) ? 0 : Number(component.cellValue(rowIndex, "Percentage"));
                                        var capital = Math.round(percentage * csCapital / 100);
                                        var expense = Math.round(percentage * csExpense / 100);
                                        var operLease = Math.round(percentage * csOperLease / 100);
                                        var totalVal = capital + expense + operLease;

                                        //Recalculate all fields if change in percentage
                                        component.cellValue(rowIndex, "Capital", capital);
                                        component.cellValue(rowIndex, "Expense", expense);
                                        component.cellValue(rowIndex, "OperLease", operLease);
                                        component.cellValue(rowIndex, "Total", totalVal);
                                    }, 100);
                                }
                            }
                            else if (e.parentType == 'dataRow' && e.dataField == 'Category') {
                                e.editorOptions.onValueChanged = function (e) {
                                    onValueChanged.call(this, e);
                                    // Emulating a web service call  
                                    window.setTimeout(function () {
                                        var numCateg = Number(component.cellValue(rowIndex, "Category"));
                                        var percentage = isNaN(Number(component.cellValue(rowIndex, "Percentage"))) ? 0 : Number(component.cellValue(rowIndex, "Percentage"));
                                        var capital = 0, expense = 0, operLease = 0, totalVal = 0;

                                        switch (numCateg) {
                                            case 1: //Contingency
                                                capital = Math.round(percentage * csCapital / 100);
                                                expense = Math.round(percentage * csExpense / 100);
                                                totalVal = capital + expense + operLease;
                                                break;
                                            case 5: //Capitalized Interest
                                                capital = Math.round(percentage * csCapital / 100);
                                                totalVal = capital + expense + operLease;
                                                break;
                                            default:
                                                capital = Math.round(percentage * csCapital / 100);
                                                expense = Math.round(percentage * csExpense / 100);
                                                operLease = Math.round(percentage * csOperLease / 100);
                                                totalVal = capital + expense + operLease;
                                                break;
                                        }

                                        //Recalculate all fields if change in category
                                        component.cellValue(rowIndex, "Capital", capital);
                                        component.cellValue(rowIndex, "Expense", expense);
                                        component.cellValue(rowIndex, "OperLease", operLease);
                                        component.cellValue(rowIndex, "Total", totalVal);
                                    }, 100);
                                }
                            }
                            else
                            {
                                e.editorOptions.onValueChanged = function (e)
                                {
                                    onValueChanged.call(this, e);
                                    // Emulating a web service call  
                                    window.setTimeout(function ()
                                    {
                                        var capital = isNaN(Number(component.cellValue(rowIndex, "Capital"))) ? 0 : Number(component.cellValue(rowIndex, "Capital"));
                                        var expense = isNaN(Number(component.cellValue(rowIndex, "Expense"))) ? 0 : Number(component.cellValue(rowIndex, "Expense"));
                                        var operLease = isNaN(Number(component.cellValue(rowIndex, "OperLease"))) ? 0 : Number(component.cellValue(rowIndex, "OperLease"));
                                        var totalVal = capital + expense + operLease;
                                        //Recalculate Total
                                        component.cellValue(rowIndex, "Total", totalVal);
                                    }, 100);
                                }
                            }
                        },
                        onRowValidating: function (e) {
                            //alert("RowValidating");
                            var totalCapital = 0;
                            var totalExpense = 0;
                            var totalOperLease = 0;

                            var costSheet = $('#jsGridCostSheet').dxDataGrid('instance');
                            var rows = costSheet.getVisibleRows();

                            for (var row = 0; row < rows.length; row++) 
                            {
                                totalCapital += Number(costSheet.cellValue(row, "Quantity")) * Number(costSheet.cellValue(row, "Capital"));
                                totalExpense += Number(costSheet.cellValue(row, "Quantity")) * Number(costSheet.cellValue(row, "Expense"));
                                totalOperLease += Number(costSheet.cellValue(row, "Quantity")) * Number(costSheet.cellValue(row, "OperLease"));
                            }

                            //Check for the correct values before submission
                            var Percentage = (e.newData.Percentage) ? Number(e.newData.Percentage) : Number(e.oldData.Percentage);
                            var Category = (e.newData.Category) ? Number(e.newData.Category) : Number(e.oldData.Category);
                            var Capital = 0, Expense = 0, OperLease = 0;

                            switch (Category) 
                            {
                                case 1:
                                    Capital = Math.round((Percentage * totalCapital) / (100));
                                    Expense = Math.round((Percentage * totalExpense) / (100));
                                    break;
                                case 5:
                                    Capital = Math.round((Percentage * totalCapital) / (100));
                                    break;
                                default:
                                    Capital = Math.round((Percentage * totalCapital) / (100));
                                    Expense = Math.round((Percentage * totalExpense) / (100));
                                    OperLease = Math.round((Percentage * totalOperLease) / (100));
                                    break;
                            }

                            //Make sure to set the values
                            e.newData.Capital = Capital;
                            e.newData.Expense = Expense;
                            e.newData.OperLease = OperLease;
                            e.newData.Total = Capital + Expense + OperLease;
                        },
                        onContentReady: function (e) {
                            console.log('onContentReady - fixedCostItems: ' + fixedCostItems);
                            refreshFixedCostTotals();   //Update the fixed summary datagrid
                        }
                    });
                });
            }
            catch (e) {
                console.log('Exception in CarForm3.aspx.populateFixedCostsNotReadOnly(): ' + e.message + ', ' + e.stack);
            }
        };

        function populateSpendForecastReadOnly()
        {
            try
            {
                console.log('In CarForm3.aspx.populateSpendForecastReadOnly().');

                var months = ["Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"];

                var projCapitalSpending = 0;

                var spendForecastItems = new DevExpress.data.CustomStore({
                    key: "ProjSpendingRowId",
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;
                        $.ajax({
                            url: operationUriPrefix + "odata/vSpendForecasts?$filter=CARId eq " + gCarId,
                            dataType: "json",
                            data: args,
                            success: function (result) {
                                //console.log('In CarForm3.aspx.populateSpendForecastReadOnly().spendForecastSummaryItems.vSpendForecasts.result.value: ' + JSON.stringify(result.value));
                                var sfItems = result.value.sort(compare);
                                var fiscalYear = gCar.FiscalYear;
                                var spendingRows = [];

                                if (sfItems.length < 1) {
                                    console.log('In CarForm3.aspx.populateSpendForecastReadOnly().spendForecastSummaryItems.vSpendForecasts: No data returned.');
                                    // Since no data was returned, we have to get the start and end date, and create the dxDataGrid on the fly.
                                    var startDate = new Date(gCar.StartDate);
                                    var endDate = new Date(gCar.EndDate);

                                    if (startDate == null || endDate == null) {
                                        alert('5: Before you can enter "Spend Forecast" information, you must choose "Project Start Date" and "Completion Date" on the "BASIC INFO" tab.');
                                        $('#tabs').tabs({ active: 0 }); // The dates weren't filled out, so take the user back to the 'BASIC INFO' tab.
                                    }
                                    else {
                                        var spendingRow = []; // We need to initalize a new spending row.
                                        spendingRow = { "ProjSpendingRowId": 0, "Title": null, "Forecast Total": null };

                                        //Create new method to determine the months from start to end dates - RHASSELL 11/11/19
                                        var date = new Date(startDate);
                                        while (date <= endDate) {
                                            //set column name of spending forecast
                                            var columnName = months[date.getMonth()] + " " + date.getFullYear();
                                            spendingRow[columnName] = null;
                                            //Set the date to the first day of next month
                                            date.setMonth(date.getMonth() + 1, 1);
                                        }
                                        spendingRows.push(spendingRow);
                                    }
                                }
                                else 
                                {
                                    // This data comes in as several rows for each Spending row, so we have to merge all these lines into 1 line for each Spending row.
                                    var spendingRow = []; // We need to initalize a new spending row.
                                    var spendingRows = [];
                                    var projSpendingRowId, oldProjSpendingRowId;
                                    var startDate = new Date(gCar.StartDate);
                                    var endDate = new Date(gCar.EndDate);

                                    for (var i = 0; i < sfItems.length; i++) {
                                        projSpendingRowId = sfItems[i].ProjSpendingRowId;
                                        if (projSpendingRowId == oldProjSpendingRowId) {
                                            //Set the monthly spending rates for the current spending row.
                                            var sfDate = new Date(sfItems[i].MonthStartDate);
                                            spendingRow[months[sfDate.getMonth()] + " " + sfDate.getFullYear()] = sfItems[i].Spend;
                                        }
                                        else //Create the new spending row
                                        {
                                            if (spendingRow) {
                                                spendingRows.push(spendingRow); // Add our row, now that we have it completed. The if statement accomodate for the first time through.
                                            }

                                            spendingRow = []; //We need to initalize a new spending row.
                                            spendingRow = { "ProjSpendingRowId": sfItems[i].ProjSpendingRowId, "Title": sfItems[i].Title, "Forecast Total": null };

                                            var date = new Date(startDate);
                                            while (date <= endDate) {
                                                //Set column name of spending forecast
                                                var columnName = months[date.getMonth()] + " " + date.getFullYear();
                                                //Set the date to the first day of next month
                                                date.setMonth(date.getMonth() + 1, 1);
                                            }

                                            var sfDate = new Date(sfItems[i].MonthStartDate);
                                            spendingRow[months[sfDate.getMonth()] + " " + sfDate.getFullYear()] = sfItems[i].Spend;

                                            //console.log('spendingRow: ' + JSON.stringify(spendingRow));
                                            oldProjSpendingRowId = sfItems[i].ProjSpendingRowId;
                                        }
                                    }

                                    spendingRows.push(spendingRow); // Add our row, now that we have it completed. // This line gets the last one! :)
                                    console.log('In CarForm3.aspx.populateSpendForecastReadOnly().spendForecastSummaryItems.spendingRows: ' + JSON.stringify(spendingRows));

                                    // Remove the empty row we used to set up our json object.
                                    for (var k = 0; k < spendingRows.length; k++) {
                                        //console.log('dataGridRows[k].Title: ' + dataGridRows[k].Title);
                                        if (spendingRows[k].Title == null) {
                                            delete spendingRows[k];
                                        }
                                    }
                                }
                                deferred.resolve(spendingRows, {});
                            },
                            error: function (data) {
                                //lpSpinner.Hide();
                                var error = JSON.parse(data.responseText)["odata.error"];
                                var errormsg = 'Exception in CarForm3.aspx.populateSpendForecastReadOnly().costSheetItems.CustomStore.load(): ' + error.message.value;
                                if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                deferred.reject("Data Loading Error : " + errormsg);
                            },
                            timeout: 60000
                        });
                        return deferred.promise();
                    }
                });

                var spendForecastSummaryItems = new DevExpress.data.CustomStore({
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;
                        $.ajax({
                            url: operationUriPrefix + "odata/vSpendForecasts?$filter=CARId eq " + gCarId,
                            dataType: "json",
                            data: args,
                            success: function (result) 
                            {
                                //console.log('In CarForm3.aspx.populateSpendForecastReadOnly().spendForecastSummaryItems.vSpendForecasts.result.value: ' + JSON.stringify(result.value));
                                var sfItems = result.value;
                                var dataGridRows = [];
                                var fiscalYear = gCar.FiscalYear;
                                
                                if (sfItems.length < 1) 
                                {
                                    console.log('In CarForm3.aspx.populateSpendForecastReadOnly().spendForecastSummaryItems.vSpendForecasts: No data returned.');
                                    // Since no data was returned, we have to get the start and end date, and create the dxDataGrid on the fly.
                                    var startDate = new Date(gCar.StartDate);
                                    var endDate = new Date(gCar.EndDate);

                                    if (startDate == null || endDate == null) {
                                        alert('5: Before you can enter "Spend Forecast" information, you must choose "Project Start Date" and "Completion Date" on the "BASIC INFO" tab.');
                                        $('#tabs').tabs({ active: 0 }); // The dates weren't filled out, so take the user back to the 'BASIC INFO' tab.
                                    }
                                    else {
                                        var dataGridRow = []; // We need to initalize a new spending row.
                                        var dataGridRow_MonthSpending = { "ProjSpendingRowId": 0, "Title": "Month Spending", "Forecast Total": null };
                                        var dataGridRow_ToDateSpending = { "ProjSpendingRowId": 0, "Title": "To Date Spending", "Forecast Total": null };
                                        //Create new method to determine the months from start to end dates - RHASSELL 11/11/19
                                        var date = new Date(startDate);
                                        while (date <= endDate) {
                                            //set column name of spending forecast
                                            var columnName = months[date.getMonth()] + " " + date.getFullYear();
                                            dataGridRow_MonthSpending[columnName] = 0;
                                            dataGridRow_ToDateSpending[columnName] = 0;
                                            //Set the date to the first day of next month
                                            date.setMonth(date.getMonth() + 1, 1);
                                        }
                                        dataGridRows.push(dataGridRow_MonthSpending);
                                        dataGridRows.push(dataGridRow_ToDateSpending);
                                    }
                                }
                                else 
                                {
                                    // This data comes in as several rows for each Spending row, so we have to merge all these lines into 1 line for each Spending row.
                                    var spendingRow;
                                    var spendingRows = [];
                                    var projSpendingRow = [];
                                    var projSpendingRowId, oldProjSpendingRowId;
                                    var startDate = new Date(gCar.StartDate);
                                    var endDate = new Date(gCar.EndDate);
                                    var monthList = [];

                                    for (var i = 0; i < sfItems.length; i++) {
                                        projSpendingRowId = sfItems[i].ProjSpendingRowId;
                                        if (projSpendingRowId == oldProjSpendingRowId) {
                                            //Set the monthly spending rates for the current spending row.
                                            var sfDate = new Date(sfItems[i].MonthStartDate);
                                            spendingRow[months[sfDate.getMonth()] + " " + sfDate.getFullYear()] = sfItems[i].Spend;
                                        }
                                        else //Create the new spending row
                                        {
                                            if (spendingRow) {
                                                spendingRows.push(spendingRow); // Add our row, now that we have it completed. The if statement accomodate for the first time through.
                                            }

                                            spendingRow = []; //We need to initalize a new spending row.
                                            spendingRow = { "ProjSpendingRowId": sfItems[i].ProjSpendingRowId, "Title": sfItems[i].Title, "Forecast Total": null };

                                            var date = new Date(startDate);
                                            while (date <= endDate) {
                                                //Set column name of spending forecast
                                                var columnName = months[date.getMonth()] + " " + date.getFullYear();
                                                //Add column to month list
                                                monthList.push(columnName);
                                                //Set the date to the first day of next month
                                                date.setMonth(date.getMonth() + 1, 1);
                                            }
                                            
                                            //Remove the duplicates
                                            var uniqueMonths = [];
                                            $.each(monthList, function(i, el){
                                                if ($.inArray(el, uniqueMonths) === -1) {
                                                    uniqueMonths.push(el);
                                                }
                                            });

                                            var sfDate = new Date(sfItems[i].MonthStartDate);
                                            spendingRow[months[sfDate.getMonth()] + " " + sfDate.getFullYear()] = sfItems[i].Spend;

                                            //console.log('spendingRow: ' + JSON.stringify(spendingRow));
                                            oldProjSpendingRowId = sfItems[i].ProjSpendingRowId;
                                        }
                                    }

                                    spendingRows.push(spendingRow); // Add our row, now that we have it completed. // This line gets the last one! :)
                                    console.log('In CarForm3.aspx.populateSpendForecastReadOnly().spendForecastSummaryItems.spendingRows: ' + JSON.stringify(spendingRows));

                                    // Remove the empty row we used to set up our json object.
                                    for (var k = 0; k < spendingRows.length; k++) {
                                        //console.log('dataGridRows[k].Title: ' + dataGridRows[k].Title);
                                        if (spendingRows[k].Title == null) {
                                            delete spendingRows[k];
                                        }
                                    }

                                    //
                                    // Now that we have our data formatted nicely, let's add/calculate the totals/summary rows at the bottom.
                                    //
                                    // "Month Spending" & "To Date Spending" rows:
                                    var dataGridRow_MonthSpending = { "ProjSpendingRowId": 0, "Title": "Month Spending", "Forecast Total": null };
                                    var dataGridRow_ToDateSpending = { "ProjSpendingRowId": 0, "Title": "To Date Spending", "Forecast Total": null };
                                    var forecastTotal = 0;
                                    var toDateTotal = 0;
                                    for (var k = 0; k < uniqueMonths.length; k++)
                                    {
                                        var monthlyTotal = 0;
                                        for (var j = 0; j < spendingRows.length; j++) 
                                        {
                                            //Add months to get the total
                                            monthlyTotal += Number(spendingRows[j][uniqueMonths[k]]);
                                            forecastTotal += Number(spendingRows[j][uniqueMonths[k]]);
                                        }

                                        toDateTotal += monthlyTotal;
                                        var colName = uniqueMonths[k];
                                        dataGridRow_MonthSpending[colName] = monthlyTotal;
                                        dataGridRow_ToDateSpending[colName] = toDateTotal;
                                    }

                                    dataGridRow_MonthSpending["Forecast Total"] = forecastTotal;
                                    dataGridRows.push(dataGridRow_MonthSpending);
                                    dataGridRows.push(dataGridRow_ToDateSpending);
                                }

                                deferred.resolve(dataGridRows, {});
                            },
                            error: function (data) {
                                //lpSpinner.Hide();
                                var error = JSON.parse(data.responseText)["odata.error"];
                                var errormsg = 'Exception in CarForm3.aspx.populateSpendForecastReadOnly().costSheetItems.CustomStore.load(): ' + error.message.value;
                                if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                deferred.reject("Data Loading Error : " + errormsg);
                            },
                            timeout: 60000
                        });
                        return deferred.promise();
                    }
                });

                var gridSpendForecastInstance = $("#jsGridSpendForecast").dxDataGrid({
                    dataSource: {
                        store: spendForecastItems
                    },
                    loadPanel: {
                        enabled: false
                    },
                    cacheEnabled: true,
                    editing: {
                        mode: "row",
                        allowUpdating: false,
                        allowDeleting: false,
                        allowAdding: false
                    },
                    remoteOperations: false,
                    searchPanel: {
                        visible: false
                    },
                    showColumnHeaders: true,
                    allowColumnReordering: false,
                    allowColumnResizing: false,
                    rowAlternationEnabled: false,
                    showBorders: true,
                    filterRow: { visible: false },
                    customizeColumns: function (columns) {
                        var widthPercent = Math.round(85 / columns.length);
                        // Make columns visible, set widths, etc.
                        $.each(columns, function (_, column) {
                            if (column.dataField == 'ProjSpendingRowId') {
                                column.visible = false; // We want this row so we can get the value, but we don't want the user to see it.
                            }
                            else if (column.dataField == 'Title') {
                                console.log('In gridSpendForecastSummaryInstance: Setting Title column to 15%.');
                                column.width = '15%';
                            }
                            else {
                                console.log('In gridSpendForecastSummaryInstance: Setting columns to the custom %.');
                                column.width = widthPercent.toString() + '%';
                                column.format = { type: "currency", precision: 0 } // This puts the comma in our currency values.
                                //column.validationRules = [{ type: "stringLength", min: 1, message: "A spend value of zero or more is required for this month..." }];
                            }
                        });
                    }
                });

                var gridSpendForecastSummaryInstance = $("#jsGridSpendForecastSummary").dxDataGrid({
                    dataSource: {
                        store: spendForecastSummaryItems
                    },
                    loadPanel: {
                        enabled: false
                    },
                    cacheEnabled: true,
                    editing: {
                        mode: "row",
                        allowUpdating: false,
                        allowDeleting: false,
                        allowAdding: false
                    },
                    remoteOperations: false,
                    searchPanel: {
                        visible: false
                    },
                    showColumnHeaders: false,
                    allowColumnReordering: false,
                    allowColumnResizing: false,
                    rowAlternationEnabled: true,
                    showBorders: true,
                    filterRow: { visible: false },
                    customizeColumns: function (columns) {
                        var widthPercent = Math.round(85 / columns.length);
                        // Make columns visible, set widths, etc.
                        $.each(columns, function (_, column) {
                            if (column.dataField == 'ProjSpendingRowId') {
                                column.visible = false; // We want this row so we can get the value, but we don't want the user to see it.
                            } else if (column.dataField == 'Title') {
                                console.log('In gridSpendForecastSummaryInstance: Setting Title column to 15%.');
                                column.width = '15%';
                            }
                            else {
                                console.log('In gridSpendForecastSummaryInstance: Setting columns to the custom %.');
                                column.width = widthPercent.toString() + '%';
                                column.format = { type: "currency", precision: 0 } // This puts the comma in our currency values.
                            }
                        });
                    },
                    onCellPrepared: function (e) {
                        if (e.rowType === "data") {
                            e.cellElement.css({ "font-style": "italic", "font-weight": "bold" });
                        }
                    }
                });
            } catch (e) {
                console.log('Exception in CarForm3.aspx.populateSpendForecastReadOnly(): ' + e.message + ', ' + e.stack);
            }
        };

        Date.prototype.addDays = function (days) {
            var date = new Date(this.valueOf());
            date.setDate(date.getDate() + days);
            return date;
        };

        function compare(a, b) 
        {
            const projRowIdA = a.ProjSpendingRowId;
            const projRowIdB = b.ProjSpendingRowId;
            const dateA = a.MonthStartDate;
            const dateB = b.MonthStartDate;
      
            let comparison = 0;
            if (dateA > dateB) 
            {
                comparison = 1;
            } 
            if (dateA < dateB) 
            {
                comparison = -1;
            }
            if (projRowIdA > projRowIdB) 
            {
                comparison = 1;
            } 
            if (projRowIdA < projRowIdB) 
            {
                comparison = -1;
            }
            return comparison;
        };

        function populateSpendForecastNotReadOnly() {
            try {
                console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().');

                var months = ["Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec"];

                var spendForecastItems = new DevExpress.data.CustomStore({
                    key: "ProjSpendingRowId",
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;
                        $.ajax({
                            url: operationUriPrefix + "odata/vSpendForecasts?$filter=CARId eq " + gCarId,
                            dataType: "json",
                            data: args,
                            success: function (result) {
                                //console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastSummaryItems.vSpendForecasts.result.value: ' + JSON.stringify(result.value));
                                var sfItems = result.value.sort(compare);

                                var fiscalYear = gCar.FiscalYear;
                                var spendingRows = [];

                                if (sfItems.length < 1) {
                                    console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastSummaryItems.vSpendForecasts: No data returned.');
                                    // Since no data was returned, we have to get the start and end date, and create the dxDataGrid on the fly.
                                    var startDate = new Date(gCar.StartDate);
                                    var endDate = new Date(gCar.EndDate);

                                    if (startDate == null || endDate == null) {
                                        alert('5: Before you can enter "Spend Forecast" information, you must choose "Project Start Date" and "Completion Date" on the "BASIC INFO" tab.');
                                        $('#tabs').tabs({ active: 0 }); // The dates weren't filled out, so take the user back to the 'BASIC INFO' tab.
                                    }
                                    else {
                                        var spendingRow = []; // We need to initalize a new spending row.
                                        spendingRow = { "ProjSpendingRowId": 0, "Title": "Add New Spend Forecast", "Forecast Total": null };

                                        //Create new method to determine the months from start to end dates - RHASSELL 11/11/19
                                        var date = new Date(startDate);
                                        while (date <= endDate) {
                                            //set column name of spending forecast
                                            var columnName = months[date.getMonth()] + " " + date.getFullYear();
                                            spendingRow[columnName] = 0;
                                            //Set the date to the first day of next month
                                            date.setMonth(date.getMonth() + 1, 1);
                                        }
                                        spendingRows.push(spendingRow);
                                    }
                                }
                                else 
                                {
                                    // This data comes in as several rows for each Spending row, so we have to merge all these lines into 1 line for each Spending row.
                                    var spendingRow;
                                    var spendingRows = [];
                                    var projSpendingRow = [];
                                    var projSpendingRowId, oldProjSpendingRowId;
                                    var startDate = new Date(gCar.StartDate);
                                    var endDate = new Date(gCar.EndDate);


                                    for (var i = 0; i < sfItems.length; i++) {
                                        projSpendingRowId = sfItems[i].ProjSpendingRowId;
                                        if (projSpendingRowId == oldProjSpendingRowId) {
                                            //Set the monthly spending rates for the current spending row.
                                            var sfDate = new Date(sfItems[i].MonthStartDate);
                                            spendingRow[months[sfDate.getMonth()] + " " + sfDate.getFullYear()] = sfItems[i].Spend;
                                        }
                                        else //Create the new spending row
                                        {
                                            if (spendingRow) {
                                                spendingRows.push(spendingRow); // Add our row, now that we have it completed. The if statement accomodate for the first time through.
                                            }

                                            spendingRow = []; //We need to initalize a new spending row.
                                            spendingRow = { "ProjSpendingRowId": sfItems[i].ProjSpendingRowId, "Title": sfItems[i].Title, "Forecast Total": null };

                                            var date = new Date(startDate);
                                            while (date <= endDate) {
                                                //Set column name of spending forecast
                                                var columnName = months[date.getMonth()] + " " + date.getFullYear();
                                                //Set the date to the first day of next month
                                                date.setMonth(date.getMonth() + 1, 1);
                                            }

                                            var sfDate = new Date(sfItems[i].MonthStartDate);
                                            spendingRow[months[sfDate.getMonth()] + " " + sfDate.getFullYear()] = sfItems[i].Spend;

                                            //console.log('spendingRow: ' + JSON.stringify(spendingRow));
                                            oldProjSpendingRowId = sfItems[i].ProjSpendingRowId;
                                        }
                                    }

                                    spendingRows.push(spendingRow); // Add our row, now that we have it completed. // This line gets the last one! :)
                                    console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastSummaryItems.spendingRows: ' + JSON.stringify(spendingRows));

                                    // Remove the empty row we used to set up our json object.
                                    for (var k = 0; k < spendingRows.length; k++) {
                                        //console.log('dataGridRows[k].Title: ' + dataGridRows[k].Title);
                                        if (spendingRows[k].Title == null) {
                                            delete spendingRows[k];
                                        }
                                    }
                                }
                                deferred.resolve(spendingRows, {});
                            },
                            error: function (data) {
                                //lpSpinner.Hide();
                                var error = JSON.parse(data.responseText)["odata.error"];
                                var errormsg = 'Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().costSheetItems.CustomStore.load(): ' + error.message.value;
                                if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                deferred.reject("Data Loading Error : " + errormsg);
                            },
                            timeout: 60000
                        });
                        return deferred.promise();
                    },
                    insert: function (values) {
                        //lpSpinner.SetText('Updating the Spend Forecast...');
                        if (values) { // Just checking if we need to save anything.
                            // Save the "Title/Name".
                            var title = values["Title"]; // The "Title/Name" value.
                            var updateJson = { "CARId": gCarId, "Name": title };
                            console.log('INSERT: updateJson: ' + JSON.stringify(updateJson) + ', values: ' + JSON.stringify(values)); // eg: INSERT: CARID: 896, values: {"Title":"test","July 2019":1,"Aug 2019":2,"Sept 2019":3,"Oct 2019":4}
                            $.ajax({
                                url: operationUriPrefix + "odata/ProjSpendingRows",
                                dataType: "json",
                                contentType: "application/json",
                                type: "Post",
                                data: JSON.stringify(updateJson)
                            }).done(function (result2) {
                                try {
                                    console.log('SUCCESSFULLY inserted into ProjSpendingRows: ' + JSON.stringify(result2)); // eg: SUCCESSFULLY called Patch 999: {"odata.metadata":"https://localhost:44347/odata/$metadata#ProjSpendingRows/@Element","ProjSpendingRowId":569,"CARId":896,"CostSheetId":null,"Name":"test5"}
                                    var projSpendingRowId = result2.ProjSpendingRowId;

                                    var updateJsons = [];
                                    var startDT = $("#StartDate").datepicker('getDate');
                                    var endDT = $("#EndDate").datepicker('getDate');
                                    for (var dt = startDT; dt < endDT.addDays(1); dt.setMonth(dt.getMonth() + 1, 1)) {
                                        console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems. dt: ' + dt + ', getMonth(): ' + dt.getMonth());
                                        var columnName = months[dt.getMonth()] + ' ' + dt.getFullYear();
                                        var monthStartDate = new Date(dt.getFullYear(), dt.getMonth(), 1);
                                        var spend = values[columnName];
                                        var updateJson = { "ProjSpendingRowId": projSpendingRowId, "OrdinalMonth": dt.getMonth(), "MonthStartDate": monthStartDate, "Spend": spend };
                                        console.log('updateJson: ' + JSON.stringify(updateJson));

                                        $.ajax({
                                            url: operationUriPrefix + "odata/ProjSpendings",
                                            dataType: "json",
                                            contentType: "application/json",
                                            type: "Post",
                                            data: JSON.stringify(updateJson)
                                        }).done(function (result2) {
                                            try {
                                                console.log('Successfully saved spend forecast: result2: ' + result2);
                                                $("#jsGridSpendForecast").dxDataGrid("instance").refresh();
                                                $("#jsGridSpendForecastSummary").dxDataGrid("instance").refresh();
                                                populateForecastParameters();   //update the spend forecast parameters
                                                toggleAlertSpendForecastIsEmpty(gCarId);
                                            }
                                            catch (e) {
                                                console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.insert: ' + e.message + ', ' + e.stack);
                                            }
                                        }).fail(function (data) {
                                            console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.insert: ' + JSON.stringify(data));
                                            var error = JSON.parse(data.responseText)["odata.error"];
                                            alert('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.insert: ' + error.message.value + ' ' + error.innererror.message); // + ', EntityValidationErrors: ' + data.EntityValidationErrors);
                                        });
                                        //updateJsons.push(updateJson);
                                    }

                                    // WE NEED TO GET THE SCREEN TO REFRESH HERE!!!!!!!!!!!!!
                                    console.log('WE NEED TO GET THE SCREEN TO REFRESH HERE!!!!!!!!!!!!!');

                                } catch (e) {
                                    console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.insert: ' + e.message + ', ' + e.stack);
                                }
                            }).fail(function (data) {
                                console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.insert: ' + JSON.stringify(data));
                                var error = JSON.parse(data.responseText)["odata.error"];
                                alert('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.insert: ' + error.message.value + ' ' + error.innererror.message); // + ', EntityValidationErrors: ' + data.EntityValidationErrors);
                            });
                        }
                        else {
                            console.log('There was nothing to save back to the database.');
                            alert('There was nothing to save back to the database.');
                        }
                    },
                    update: function (keys, values) {
                        lpSpinner.SetText('Updating the Spend Forecast...');
                        //lpSpinner.Show();
                        console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update: keys: ' + JSON.stringify(keys) + ', values: ' + JSON.stringify(values)); // eg: yyyyyyyyyyyyyyyyyyyyyyyyyy values: {"July 2019":7777}
                        if (keys && values) { // Just checking if we need to save anything.
                            var columnNames = Object.keys(values); // Get the column/field names so we can decide how to save things below...
                            console.log('Object.keys(values): columnNames: ' + columnNames);
                            var projSpendingRowId = keys; // The "ProjSpendingId" value.
                            //
                            // First we check if the title has been changed. If so, save it to the database.
                            //
                            if (columnNames.indexOf('Title') > -1) {
                                var ci = columnNames.indexOf('Title');
                                var title = values[columnNames[ci]]; // The "Title/Name" value.
                                var updateJson = { "Name": title };
                                console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update.Title: Updating the Title: projSpendingRowId: ' + projSpendingRowId + ', updateJson: ' + JSON.stringify(updateJson));
                                $.ajax({
                                    url: operationUriPrefix + "odata/ProjSpendingRows(" + projSpendingRowId + ")",
                                    dataType: "json",
                                    contentType: "application/json",
                                    type: "Patch",
                                    data: JSON.stringify(updateJson)
                                }).done(function (result2) {
                                    try {
                                        //lpSpinner.Hide();
                                        if (result2) {
                                            alert('Error: ' + JSON.stringify(result2));
                                        } else {
                                            // If nothing comes back here (undefined) then it is Ok.
                                            console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update.Title: SUCCESSFULLY updated the ProjSpendingRow table: projSpendingRowId: ' + projSpendingRowId + ', ' + JSON.stringify(updateJson));
                                            // 
                                            // Now we get all of the changed spend values for the months, and save them to the database.
                                            //
                                            $.ajax({
                                                url: operationUriPrefix + "odata/ProjSpendings?$filter=ProjSpendingRowId eq " + projSpendingRowId,
                                                dataType: "json",
                                                success: function (result) {
                                                    //lpSpinner.Hide();
                                                    var rows = result.value;
                                                    console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update.Spend: projSpendingRowId: ' + projSpendingRowId + ', rows: ' + JSON.stringify(rows));
                                                    //Now that we have the ProjSpendingRow, match up the columns, get the 
                                                    var projSpendingId;
                                                    var updateJson;
                                                    for (var j = 0; j < rows.length; j++) {
                                                        var dtMonth = new Date(rows[j].MonthStartDate);
                                                        var columnName = months[dtMonth.getMonth()] + ' ' + dtMonth.getFullYear(); // eg: "Aug 2019"
                                                        var spend = values[columnName]; // The "Spend" value.
                                                        if (Number(spend) >= 0) {
                                                            //
                                                            // We have found the projSpendingId for the updated spend value.
                                                            //
                                                            projSpendingId = rows[j].ProjSpendingId;
                                                            updateJson = { "Spend": spend };
                                                            console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update.Spend: getting ready to send to DB. projSpendingId: ' + projSpendingId + ', columnName: ' + columnName + ', spend: ' + spend + ', updateJson: ' + JSON.stringify(updateJson));
                                                            // We have it!!!! Update the database
                                                            lpSpinner.SetText('Saving...');
                                                            //lpSpinner.Show();
                                                            $.ajax({
                                                                url: operationUriPrefix + "odata/ProjSpendings(" + projSpendingId + ")",
                                                                dataType: "json",
                                                                contentType: "application/json",
                                                                type: "Patch",
                                                                data: JSON.stringify(updateJson)
                                                            }).done(function (result2) {
                                                                try {
                                                                    if (result2) {
                                                                        //lpSpinner.Hide();
                                                                        alert('Error saving: ' + result2 + ', ' + JSON.stringify(result2));
                                                                    }
                                                                    else {
                                                                        console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update(1): Successfully updated DB using (' + JSON.stringify(updateJson) + '): result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                                                        $("#jsGridSpendForecast").dxDataGrid("instance").refresh();
                                                                        $("#jsGridSpendForecastSummary").dxDataGrid("instance").refresh();
                                                                        populateForecastParameters();   //update the spend forecast parameters
                                                                        toggleAlertSpendForecastIsEmpty(gCarId);
                                                                        //lpSpinner.Hide();
                                                                    }
                                                                }
                                                                catch (e) {
                                                                    //lpSpinner.Hide();
                                                                    console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update: ' + e.message + ', ' + e.stack);
                                                                }
                                                            }).fail(function (data) {
                                                                //lpSpinner.Hide();
                                                                var msg;
                                                                if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                                                    msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                                                } else {
                                                                    msg = JSON.stringify(data);
                                                                }
                                                                alert('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                                                console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update: ' + JSON.stringify(data));
                                                            });
                                                        } else {
                                                            $("#jsGridSpendForecast").dxDataGrid("instance").refresh();
                                                            $("#jsGridSpendForecastSummary").dxDataGrid("instance").refresh();
                                                        }
                                                    }
                                                },
                                                error: function (data) {
                                                    //lpSpinner.Hide();
                                                    var error = JSON.parse(data.responseText)["odata.error"];
                                                    var errormsg = 'Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update(): ' + error.message.value;
                                                    if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                                    if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                                    deferred.reject("Data Loading Error : " + errormsg);
                                                },
                                                timeout: 60000
                                            });
                                        }
                                    }
                                    catch (e) {
                                        //lpSpinner.Hide();
                                        alert('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update.Title: ' + e.message + ', ' + e.stack);
                                        console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update.Title: ' + e.message + ', ' + e.stack);
                                    }
                                }).fail(function (data) {
                                    //lpSpinner.Hide();
                                    var msg;
                                    if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                        msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                    }
                                    else {
                                        msg = JSON.stringify(data);
                                    }
                                    alert('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update.fail: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                    console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update.fail: ' + JSON.stringify(data));
                                });
                            }
                            else
                            {
                                // Now we get all of the changed spend values for the months, and save them to the database.
                                $.ajax({
                                    url: operationUriPrefix + "odata/ProjSpendings?$filter=ProjSpendingRowId eq " + projSpendingRowId,
                                    dataType: "json",
                                    success: function (result) {
                                        //lpSpinner.Hide();
                                        var rows = result.value;
                                        console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update.Spend: projSpendingRowId: ' + projSpendingRowId + ', rows: ' + JSON.stringify(rows));
                                        //Now that we have the ProjSpendingRow, match up the columns, get the 
                                        var projSpendingId;
                                        var updateJson;
                                        for (var j = 0; j < rows.length; j++) {
                                            var dtMonth = new Date(rows[j].MonthStartDate);
                                            var columnName = months[dtMonth.getMonth()] + ' ' + dtMonth.getFullYear(); // eg: "Aug 2019"
                                            var spend = values[columnName]; // The "Spend" value.
                                            console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spend: ' + spend);
                                            if (Number(spend) >= 0) {
                                                //
                                                // We have found the projSpendingId for the updated spend value.
                                                //
                                                projSpendingId = rows[j].ProjSpendingId;
                                                updateJson = { "Spend": spend };
                                                console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update.Spend: getting ready to send to DB. projSpendingId: ' + projSpendingId + ', columnName: ' + columnName + ', spend: ' + spend + ', updateJson: ' + JSON.stringify(updateJson));
                                                // We have it!!!! Update the database
                                                lpSpinner.SetText('Saving...');
                                                //lpSpinner.Show();
                                                $.ajax({
                                                    url: operationUriPrefix + "odata/ProjSpendings(" + projSpendingId + ")",
                                                    dataType: "json",
                                                    contentType: "application/json",
                                                    type: "Patch",
                                                    data: JSON.stringify(updateJson)
                                                }).done(function (result2) {
                                                    try {
                                                        if (result2) {
                                                            //lpSpinner.Hide();
                                                            alert('Error saving: ' + result2 + ', ' + JSON.stringify(result2));
                                                        }
                                                        else {
                                                            console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update(2): Successfully updated DB using (' + JSON.stringify(updateJson) + '): result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                                            $("#jsGridSpendForecast").dxDataGrid("instance").refresh();
                                                            $("#jsGridSpendForecastSummary").dxDataGrid("instance").refresh();
                                                            populateForecastParameters();   //update the spend forecast parameters
                                                            toggleAlertSpendForecastIsEmpty(gCarId);
                                                            //lpSpinner.Hide();
                                                        }
                                                    } catch (e) {
                                                        //lpSpinner.Hide();
                                                        console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update: ' + e.message + ', ' + e.stack);
                                                    }
                                                }).fail(function (data) {
                                                    //lpSpinner.Hide();
                                                    var msg;
                                                    if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                                        msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                                    } else {
                                                        msg = JSON.stringify(data);
                                                    }
                                                    alert('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                                    console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update: ' + JSON.stringify(data));
                                                    //lpSpinner.Hide();
                                                });
                                            } else {
                                                $("#jsGridSpendForecast").dxDataGrid("instance").refresh();
                                                $("#jsGridSpendForecastSummary").dxDataGrid("instance").refresh();
                                                //lpSpinner.Hide();
                                            }
                                        }
                                    },
                                    error: function (data) {
                                        //lpSpinner.Hide();
                                        var error = JSON.parse(data.responseText)["odata.error"];
                                        var errormsg = 'Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.update(): ' + error.message.value;
                                        if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                        if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                        deferred.reject("Data Loading Error : " + errormsg);
                                    },
                                    timeout: 60000
                                });
                            }
                        } else {
                            //lpSpinner.Hide();
                            console.log('There was nothing to save back to the database.');
                        }
                    },
                    remove: function (projSpendingRowId) {
                        console.log('REMOVE: projSpendingRowId: ' + projSpendingRowId);
                        //alert("removing...........");
                        $.ajax({
                            url: operationUriPrefix + "odata/ProjSpendings?$filter=ProjSpendingRowId eq " + projSpendingRowId,
                            dataType: "json",
                            success: function (result) {
                                //lpSpinner.Hide();
                                var rows = result.value;
                                console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.delete: projSpendingRowId: ' + projSpendingRowId + ', rows: ' + JSON.stringify(rows));
                                //Now that we have the ProjSpendingRow, match up the columns, get the 
                                var projSpendingId;
                                var updateJson;
                                for (var j = 0; j < rows.length; j++) {
                                    projSpendingId = rows[j].ProjSpendingId;
                                    // We have it!!!! Update the database
                                    lpSpinner.SetText('Deleting...');
                                    //lpSpinner.Show();
                                    $.ajax({
                                        url: operationUriPrefix + "odata/ProjSpendings(" + projSpendingId + ")",
                                        dataType: "json",
                                        contentType: "application/json",
                                        type: "Delete"
                                    }).done(function (result2) {
                                        try {
                                            if (result2) {
                                                //lpSpinner.Hide();
                                                alert('Error deleting: ' + result2 + ', ' + JSON.stringify(result2));
                                            } else {
                                                console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.delete: Successfully deleted from DB. result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                                $("#jsGridSpendForecast").dxDataGrid("instance").refresh();
                                                $("#jsGridSpendForecastSummary").dxDataGrid("instance").refresh();
                                                populateForecastParameters();   //update the spend forecast parameters
                                                toggleAlertSpendForecastIsEmpty(gCarId);
                                                //lpSpinner.Hide();
                                            }
                                        } catch (e) {
                                            //lpSpinner.Hide();
                                            console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.delete: ' + e.message + ', ' + e.stack);
                                        }
                                    }).fail(function (data) {
                                        //lpSpinner.Hide();
                                        var msg;
                                        if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                            msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                        } else {
                                            msg = JSON.stringify(data);
                                        }
                                        alert('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.delete: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                        console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.delete: ' + JSON.stringify(data));
                                        //lpSpinner.Hide();
                                    });
                                }
                                //
                                // This is where we delete from ProjSpendingRow table.
                                //
                                $.ajax({
                                    url: operationUriPrefix + "odata/ProjSpendingRows(" + projSpendingRowId + ")",
                                    dataType: "json",
                                    contentType: "application/json",
                                    type: "Delete"
                                }).done(function (result2) {
                                    try {
                                        if (result2) {
                                            //lpSpinner.Hide();
                                            alert('Error deleting: ' + result2 + ', ' + JSON.stringify(result2));
                                        } else {
                                            console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.delete: Successfully deleted from DB. result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                            $("#jsGridSpendForecast").dxDataGrid("instance").refresh();
                                            $("#jsGridSpendForecastSummary").dxDataGrid("instance").refresh();
                                            populateForecastParameters();   //update the spend forecast parameters
                                            toggleAlertSpendForecastIsEmpty(gCarId);
                                            //lpSpinner.Hide();
                                        }
                                    } catch (e) {
                                        //lpSpinner.Hide();
                                        console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.delete: ' + e.message + ', ' + e.stack);
                                    }
                                }).fail(function (data) {
                                    //lpSpinner.Hide();
                                    var msg;
                                    if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                        msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                    } else {
                                        msg = JSON.stringify(data);
                                    }
                                    alert('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.delete: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                    console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.delete: ' + JSON.stringify(data));
                                    //lpSpinner.Hide();
                                });
                            },
                            error: function (data) {
                                //lpSpinner.Hide();
                                var error = JSON.parse(data.responseText)["odata.error"];
                                var errormsg = 'Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.delete(): ' + error.message.value;
                                if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                deferred.reject("Data Loading Error : " + errormsg);
                            },
                            timeout: 60000
                        });
                    }
                });

                var spendForecastSummaryItems = new DevExpress.data.CustomStore({
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;

                        $.ajax({
                            url: operationUriPrefix + "odata/vSpendForecasts?$filter=CARId eq " + gCarId,
                            dataType: "json",
                            data: args,
                            success: function (result) {
                                var sfItems = result.value;

                                var dataGridRows = [];

                                if (sfItems.length < 1) 
                                {
                                    console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastSummaryItems.vSpendForecasts: No data returned.');
                                    // Since no data was returned, we have to get the start and end date, and create the dxDataGrid on the fly.
                                    var startDate = new Date(gCar.StartDate);
                                    var endDate = new Date(gCar.EndDate);

                                    if (startDate == null || endDate == null) {
                                        alert('5: Before you can enter "Spend Forecast" information, you must choose "Project Start Date" and "Completion Date" on the "BASIC INFO" tab.');
                                        $('#tabs').tabs({ active: 0 }); // The dates weren't filled out, so take the user back to the 'BASIC INFO' tab.
                                    }
                                    else {
                                        var dataGridRow = []; // We need to initalize a new spending row.
                                        var dataGridRow_MonthSpending = { "ProjSpendingRowId": 0, "Title": "Month Spending", "Forecast Total": null };
                                        var dataGridRow_ToDateSpending = { "ProjSpendingRowId": 0, "Title": "To Date Spending", "Forecast Total": null };
                                        //Create new method to determine the months from start to end dates - RHASSELL 11/11/19
                                        var date = new Date(startDate);
                                        while (date <= endDate) {
                                            //set column name of spending forecast
                                            var columnName = months[date.getMonth()] + " " + date.getFullYear();
                                            dataGridRow_MonthSpending[columnName] = 0;
                                            dataGridRow_ToDateSpending[columnName] = 0;
                                            //Set the date to the first day of next month
                                            date.setMonth(date.getMonth() + 1, 1);
                                        }
                                        dataGridRows.push(dataGridRow_MonthSpending);
                                        dataGridRows.push(dataGridRow_ToDateSpending);
                                    }
                                }
                                else 
                                {
                                    // This data comes in as several rows for each Spending row, so we have to merge all these lines into 1 line for each Spending row.
                                    var spendingRow;
                                    var spendingRows = [];
                                    var projSpendingRow = [];
                                    var projSpendingRowId, oldProjSpendingRowId;
                                    var startDate = new Date(gCar.StartDate);
                                    var endDate = new Date(gCar.EndDate);
                                    var monthList = [];

                                    for (var i = 0; i < sfItems.length; i++) {
                                        projSpendingRowId = sfItems[i].ProjSpendingRowId;
                                        if (projSpendingRowId == oldProjSpendingRowId) {
                                            //Set the monthly spending rates for the current spending row.
                                            var sfDate = new Date(sfItems[i].MonthStartDate);
                                            spendingRow[months[sfDate.getMonth()] + " " + sfDate.getFullYear()] = sfItems[i].Spend;
                                        }
                                        else //Create the new spending row
                                        {
                                            if (spendingRow) {
                                                spendingRows.push(spendingRow); // Add our row, now that we have it completed. The if statement accomodate for the first time through.
                                            }

                                            spendingRow = []; //We need to initalize a new spending row.
                                            spendingRow = { "ProjSpendingRowId": sfItems[i].ProjSpendingRowId, "Title": sfItems[i].Title, "Forecast Total": null };

                                            var date = new Date(startDate);
                                            while (date <= endDate) {
                                                //Set column name of spending forecast
                                                var columnName = months[date.getMonth()] + " " + date.getFullYear();
                                                //Add column to month list
                                                monthList.push(columnName);
                                                //Set the date to the first day of next month
                                                date.setMonth(date.getMonth() + 1, 1);
                                            }
                                            
                                            //Remove the duplicates
                                            var uniqueMonths = [];
                                            $.each(monthList, function(i, el){
                                                if ($.inArray(el, uniqueMonths) === -1) {
                                                    uniqueMonths.push(el);
                                                }
                                            });

                                            var sfDate = new Date(sfItems[i].MonthStartDate);
                                            spendingRow[months[sfDate.getMonth()] + " " + sfDate.getFullYear()] = sfItems[i].Spend;

                                            //console.log('spendingRow: ' + JSON.stringify(spendingRow));
                                            oldProjSpendingRowId = sfItems[i].ProjSpendingRowId;
                                        }
                                    }

                                    spendingRows.push(spendingRow); // Add our row, now that we have it completed. // This line gets the last one! :)
                                    console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastSummaryItems.spendingRows: ' + JSON.stringify(spendingRows));

                                    // Remove the empty row we used to set up our json object.
                                    for (var k = 0; k < spendingRows.length; k++) {
                                        //console.log('dataGridRows[k].Title: ' + dataGridRows[k].Title);
                                        if (spendingRows[k].Title == null) {
                                            delete spendingRows[k];
                                        }
                                    }

                                    //
                                    // Now that we have our data formatted nicely, let's add/calculate the totals/summary rows at the bottom.
                                    //
                                    // "Month Spending" & "To Date Spending" rows:
                                    var dataGridRow_MonthSpending = { "ProjSpendingRowId": 0, "Title": "Month Spending", "Forecast Total": null };
                                    var dataGridRow_ToDateSpending = { "ProjSpendingRowId": 0, "Title": "To Date Spending", "Forecast Total": null };
                                    var forecastTotal = 0;
                                    var toDateTotal = 0;
                                    for (var k = 0; k < uniqueMonths.length; k++)
                                    {
                                        var monthlyTotal = 0;
                                        for (var j = 0; j < spendingRows.length; j++) 
                                        {
                                            //Add months to get the total
                                            monthlyTotal += Number(spendingRows[j][uniqueMonths[k]]);
                                            forecastTotal += Number(spendingRows[j][uniqueMonths[k]]);
                                        }

                                        toDateTotal += monthlyTotal;
                                        var colName = uniqueMonths[k];
                                        dataGridRow_MonthSpending[colName] = monthlyTotal;
                                        dataGridRow_ToDateSpending[colName] = toDateTotal;
                                    }

                                    dataGridRow_MonthSpending["Forecast Total"] = forecastTotal;
                                    dataGridRows.push(dataGridRow_MonthSpending);
                                    dataGridRows.push(dataGridRow_ToDateSpending);
                                }

                                deferred.resolve(dataGridRows, {});
                            },
                            error: function (data) {
                                //lpSpinner.Hide();
                                var error = JSON.parse(data.responseText)["odata.error"];
                                var errormsg = 'Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.CustomStore.load(): ' + error.message.value;
                                if (error.innererror.message) errormsg += ' ' + error.innererror.message;
                                if (error.innererror.internalexception.message) errormsg += ' ' + error.innererror.internalexception.message;
                                deferred.reject("Data Loading Error : " + errormsg);
                            },
                            timeout: 60000
                        });
                        return deferred.promise();
                    }
                });

                var gridSpendForecastInstance = $("#jsGridSpendForecast").dxDataGrid({
                    dataSource: {
                        store: spendForecastItems
                    },
                    loadPanel: {
                        enabled: false
                    },
                    cacheEnabled: true,
                    editing: {
                        mode: "row",
                        allowUpdating: true,
                        allowDeleting: true,
                        allowAdding: true
                    },
                    showBorders: true,
                    showColumnHeaders: true,
                    allowColumnReordering: false,
                    allowColumnResizing: true,
                    columnResizingMode: "nextColumn",
                    rowAlternationEnabled: true,
                    showRowLines: true,
                    remoteOperations: false,
                    filterRow: { visible: false },
                    searchPanel: { visible: false },
                    customizeColumns: function (columns)
                    {
                        // Make columns visible, set widths, etc.
                        $.each(columns, function (_, column) {
                            if (column.dataField == 'ProjSpendingRowId') {
                                column.visible = false; // We want this row so we can get the value, but we don't want the user to see it.
                            }
                            else if (column.dataField == 'Title') {
                                column.validationRules = [{ type: "required" }];
                            }
                            else if (column.dataField == 'Forecast Total') {
                                column.allowEditing = false;
                            }
                            else {
                                column.format = { type: "currency", precision: 0 } // This puts the comma in our currency values.
                            }
                        });
                    },
                    onKeyDown: function (e) {
                        if (e.event.keyCode == 13 || e.event.keyCode == 190 || e.event.keyCode == 110)
                        {
                            console.log("SpendForecast: Enter/Decimal/Period buttons disabled.");
                            e.event.preventDefault();
                            return false;
                        }
                    },
                    onEditorPreparing: function (e) {   //RHASSELL: To-Do: update spend forecast total with each addition! 
                        //alert("onEditorPreparing");
                        var component = e.component, rowIndex = e.row && e.row.rowIndex;

                        //Added fix for backspace prevention (only when there is a value)
                        if (e.parentType == "dataRow") {
                            e.editorOptions.onKeyDown = function (arg) {
                                var value = e.element.find("input").val();
                                if (arg.event.keyCode == 8 && value.length < 1)
                                {
                                    arg.event.preventDefault();
                                    arg.event.stopPropagation();                                    
                                }
                            }
                        }


                        var onValueChanged = e.editorOptions.onValueChanged;
                        e.editorOptions.onValueChanged = function (e) {
                            onValueChanged.call(this, e);
                            //Emulating a web service call  
                            window.setTimeout(function () {
                                var forecastTotal = 0;
                                var theGrid = $('#jsGridSpendForecast').dxDataGrid('instance');

                                var rows = theGrid.getVisibleRows();
                                var numRows = rows.length;

                                var cols = theGrid.getVisibleColumns();
                                var numCols = cols.length;

                                for (var row = 0; row < numRows; row++) {
                                    for (var col = 0; col < numCols - 1; col++) {
                                        var cellValue = theGrid.cellValue(row, cols[col].dataField);
                                        if (cols[col].dataType === "number")
                                            forecastTotal += Number(cellValue);
                                    }
                                }
                                // Update the screen
                                var projectedCapital = Number($('#projectedCapitalSpending').text().replace(/,/g, ''));
                                var amountLeft = projectedCapital - forecastTotal;
                                generateLabel('amountForecast', commaSeparateNumber(forecastTotal));
                                generateLabel('amountLeftToForecast', commaSeparateNumber(amountLeft));
                            }, 500);
                        }
                    },
                    onInitNewRow: function(e) {
                        var columns = e.component.getVisibleColumns();                
                        for (var colIndex = 0; colIndex < columns.length; colIndex++) 
                        {
                            if (columns[colIndex]) 
                            {
                                if (columns[colIndex].dataField === "Title") {
                                    e.data[columns[colIndex].dataField] = "Add New Spend Forecast";
                                }
                                else if (columns[colIndex].dataField === "Forecast Total") {
                                    e.data[columns[colIndex].dataField] = null;
                                }
                                else {
                                    e.data[columns[colIndex].dataField] = "0";
                                }
                            }
                        }
                    },
                    onRowValidating: function (e) {
                        //alert(RowValidating);
                        //This generates the initial spending row
                        //If ProjSpendingRowId is 0, then must get latest add this record and set to new value
                        var ProjSpendingID = 0;
                        if (e.oldData && e.oldData.ProjSpendingRowId == 0) 
                        {
                            var values = { "Title": e.component.cellValue(0, "Title") };
                            var startDate = new Date(gCar.StartDate);
                            var endDate = new Date(gCar.EndDate);

                            //Create new method to determine the months from start to end dates - RHASSELL 11/11/19
                            var date = new Date(startDate);
                            while (date <= endDate) {
                                //set column name of spending forecast
                                var columnName = months[date.getMonth()] + " " + date.getFullYear();
                                values[columnName] = e.newData[columnName];
                                //Set the date to the first day of next month
                                date.setMonth(date.getMonth() + 1, 1);
                            }

                            var updateJson = { "CARId": gCarId, "Name": e.component.cellValue(0, "Title") };
                            console.log('INSERT: updateJson: ' + JSON.stringify(updateJson) + ', values: ' + JSON.stringify(values)); //values: {"Title":"test","July 2019":1,"Aug 2019":2,"Sept 2019":3,"Oct 2019":4}

                            $.ajax({
                                url: operationUriPrefix + "odata/ProjSpendingRows",
                                dataType: "json",
                                contentType: "application/json",
                                type: "Post",
                                data: JSON.stringify(updateJson)
                            }).done(function (result2) {
                                try {
                                    console.log('SUCCESSFULLY inserted into ProjSpendingRows: ' + JSON.stringify(result2)); // eg: SUCCESSFULLY called Patch 999: {"odata.metadata":"https://localhost:44347/odata/$metadata#ProjSpendingRows/@Element","ProjSpendingRowId":569,"CARId":896,"CostSheetId":null,"Name":"test5"}
                                    var projSpendingRowId = result2.ProjSpendingRowId;

                                    var startDT = $("#StartDate").datepicker('getDate');
                                    var endDT = $("#EndDate").datepicker('getDate');
                                    for (var dt = startDT; dt < endDT.addDays(1); dt.setMonth(dt.getMonth() + 1, 1)) {
                                        console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems. dt: ' + dt + ', getMonth(): ' + dt.getMonth());
                                        var columnName = months[dt.getMonth()] + ' ' + dt.getFullYear();
                                        var monthStartDate = new Date(dt.getFullYear(), dt.getMonth(), 1);
                                        var spend = values[columnName];
                                        var updateJson = { "ProjSpendingRowId": projSpendingRowId, "OrdinalMonth": dt.getMonth(), "MonthStartDate": monthStartDate, "Spend": spend };
                                        console.log('updateJson: ' + JSON.stringify(updateJson));

                                        $.ajax({
                                            url: operationUriPrefix + "odata/ProjSpendings",
                                            dataType: "json",
                                            contentType: "application/json",
                                            type: "Post",
                                            data: JSON.stringify(updateJson)
                                        }).done(function (result2) {
                                            try {
                                                console.log('In CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.insert: result2: ' + result2);
                                                ProjSpendingID = projSpendingRowId;
                                                $("#jsGridSpendForecast").dxDataGrid("instance").refresh();
                                                $("#jsGridSpendForecastSummary").dxDataGrid("instance").refresh();
                                                populateForecastParameters();   //update the spend forecast parameters
                                                toggleAlertSpendForecastIsEmpty(gCarId);
                                                e.newData.ProjSpendingRowId = ProjSpendingID;
                                            }
                                            catch (e) {
                                                console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.insert: ' + e.message + ', ' + e.stack);
                                            }
                                        }).fail(function (data) {
                                            console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.insert: ' + JSON.stringify(data));
                                            alert('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.insert: ' + JSON.stringify(data));
                                        });
                                    }

                                    // WE NEED TO GET THE SCREEN TO REFRESH HERE!!!!!!!!!!!!!
                                    console.log('WE NEED TO GET THE SCREEN TO REFRESH HERE!!!!!!!!!!!!!');
                                }
                                catch (e) {
                                    console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.insert: ' + e.message + ', ' + e.stack);
                                }
                            }).fail(function (data) {
                                console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.fail: ' + JSON.stringify(data));
                                alert('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly().spendForecastItems.fail: ' + JSON.stringify(data));
                            });

                            //if (e.isValid && e.newData.Login === "Administrator") {
                            //    e.isValid = false;
                            //    e.errorText = "Your cannot log in as Administrator";
                            //}
                        }
                    }
                });

                var gridSpendForecastSummaryInstance = $("#jsGridSpendForecastSummary").dxDataGrid({
                    dataSource: {
                        store: spendForecastSummaryItems
                    },
                    loadPanel: { enabled: false },
                    cacheEnabled: true,
                    editing: {
                        mode: "row",
                        allowUpdating: true,
                        allowDeleting: false,
                        allowAdding: false
                    },
                    showColumnHeaders: false,
                    allowColumnReordering: false,
                    allowColumnResizing: true,
                    columnResizingMode: "nextColumn",
                    rowAlternationEnabled: true,
                    showBorders: true,
                    remoteOperations: false,
                    searchPanel: { visible: false },
                    filterRow: { visible: false },
                    customizeColumns: function (columns)
                    {
                        // Make columns visible, set widths, etc.
                        $.each(columns, function (_, column)
                        {
                            if (column.dataField == 'ProjSpendingRowId') {
                                column.visible = false; // We want this row so we can get the value, but we don't want the user to see it.
                            } 
                            else if (column.dataField == 'Title') {
                                column.allowEditing = false;
                            }
                            else if (column.dataField == 'Forecast Total') {
                                column.allowEditing = false;
                                column.format = { type: "currency", precision: 0 } // This puts the comma in our currency values.
                            }
                            else
                            {
                                column.allowEditing = false;
                                column.format = { type: "currency", precision: 0 } // This puts the comma in our currency values.
                            }
                        });
                    },
                    onCellPrepared: function (e) {
                        if (e.rowType === "data") {
                            //Set all summary cells to bold and italic
                            e.cellElement.css({ "font-style": "italic", "font-weight": "bold" });
                            //Remove the edit link in summary grid because its not needed
                            e.cellElement.find(".dx-link-edit").remove();
                            //e.cellElement.css({ "color": "dark charcoal" /*"#333333"*/ });
                        }
                    }
                });
            } catch (e) {
                console.log('Exception in CarForm3.aspx.populateSpendForecastNotReadOnly(): ' + e.message + ', ' + e.stack);
            }
        };

        function populateCarDataReadOnly() {
            try {
                console.log('In CarForm3.aspx.populateCarDataReadOnly().');

                $.ajax({
                    url: operationUriPrefix + "odata/CARMasters?$filter=CARId eq " + gCarId,
                    dataType: "json",
                    success: function (result) {
                        try {
                            gCar = result.value[0];
                            //console.log(JSON.stringify(gCar));

                            var deferred = $.Deferred();
                            deferred
                                .then(
                                    function () {
                                        lpSpinner.Show();
                                    },
                                    function () {
                                        console.log('Exception in CarForm3.aspx.populateCarDataReadOnly(): Failure in lpSpinner.Show()');
                                    }
                                ).then(
                                    function () {
                                        // Populate the Location Name
                                        $.ajax({
                                            url: operationUriPrefix + "odata/Orgs?$filter=OrgId eq '" + gCar.OrgId + "'",
                                            dataType: "json"
                                        }).done(function (result) {
                                            try {
                                                var Org = result.value[0];
                                                generateLabel('Location', Org.OrgName);
                                            } catch (e) {
                                                console.log('Exception in populateCarDataReadOnly: ' + e.message + ', ' + e.stack);
                                            }
                                        });
                                    },
                                    function () {
                                        console.log('Exception in CarForm3.aspx.populateCarDataReadOnly(): Failure in populating location.');
                                    }
                                ).then(
                                    function () {
                                        // Populate the "BASIC INFO" tab, "HEADING" section.
                                        $('#lblProject').text(gCar.ProjectNumber + " - " + gCar.ProjectTitle);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating project label.');
                                    }
                                ).then(
                                    function () {
                                        generateLabel('ProjectNumber', gCar.ProjectNumber);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating project number.');
                                    }
                                ).then(
                                    function () {
                                        generateLabel('ProjectTitle', gCar.ProjectTitle);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating project title.');
                                    }
                                ).then(
                                    function () {
                                        generateLabel('CostCenterNumber', gCar.CostCenterNumber);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating cost center number.');
                                    }
                                ).then(
                                    function () {
                                        generateLabel('CostCenterDesc', gCar.CostCenterDesc);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating cost center description.');
                                    }
                                ).then(
                                    function () {
                                        generateLabel('ExchangeRate', gCar.ExchangeRate);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating exchange rate.');
                                    }
                                ).then(
                                    function () {
                                        getProjectManager(gCar.ProjManagerId);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating project manager.');
                                    }
                                ).then(
                                    function () {
                                        getProjectType(gCar.ProjectTypeId);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating project type.');
                                    }
                                ).then(
                                    function () {
                                        getProjectSponsor(gCar.ProjSponsorId);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating project sponsor.');
                                    }
                                ).then(
                                    function () {
                                        getCurrencyType(gCar.CurrencyTypeId);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating currency type.');
                                    }
                                ).then(
                                    function () {
                                        // Audit required?
                                        // #PFG-Audit
                                        if (gAllowAuditDataEntry == 'true') {
                                            //Populate Audit radio button
                                            if (gCar.AuditRequired != null) {
                                                if (gCar.AuditRequired) {
                                                    $('#AuditRequired_Yes').prop('checked', true);
                                                    $('.toggleAuditRequired').css('display', 'block');
                                                }
                                                else {
                                                    $('#AuditRequired_No').prop('checked', true);
                                                    $('.toggleAuditRequired').css('display', 'none');
                                                }
                                            }
                                            else {
                                                $('.toggleAuditRequired').css('display', 'none');
                                            }

                                            //Populate Audit Date
                                            if (gCar.AuditDate) {
                                                $('#AuditDate').val(gCar.AuditDate.substring(0, 10));
                                            }
                                        }
                                        else {
                                            if (gCar.AuditRequired != null) {
                                                if (gCar.AuditRequired) {
                                                    generateLabel('AuditRequired', 'Yes');
                                                }
                                                else {
                                                    generateLabel('AuditRequired', 'No');
                                                    $('.toggleAuditRequired').css('display', 'none');
                                                }
                                            }
                                            else {
                                                generateLabel('AuditRequired', 'N/A');
                                                $('.toggleAuditRequired').css('display', 'none');
                                            }

                                            // Audit Date
                                            if (gCar.AuditDate) {
                                                generateLabel('AuditDate', gCar.AuditDate.substring(0, 10));
                                            }
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating audit flag.');
                                    }
                                ).then(
                                    function () {
                                        // Set Audit Datepicker
                                        if (gAllowAuditDataEntry == 'true') {

                                            $("#AuditDate").datepicker({
                                                changeMonth: true,
                                                changeYear: true,
                                                firstDay: 1,
                                                dateFormat: "yy-mm-dd",
                                                showButtonPanel: true
                                            });
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in setting audit datepicker.');
                                    }
                                ).then(
                                    function () {
                                        // Get the Pillar ID to populate
                                        $.ajax({
                                            url: operationUriPrefix + "odata/Pillars?$filter=PillarId eq '" + gCar.PillarId + "'",
                                            dataType: "json"
                                        }).done(function (result) {
                                            try {
                                                var pts = result.value[0];
                                                //Populate the pillar dropdown
                                                generateLabel('Pillar', pts.Name);
                                            } catch (e) {
                                                console.log('Exception in populateCarDataReadOnly: ' + e.message + ', ' + e.stack);
                                            }
                                        });
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating pillar type.');
                                    }
                                ).then(
                                    function () {
                                        // Populate the "BASIC INFO" tab, "CAR DETAILS" section.
                                        if (gCar.CombPlantFlag != null) {
                                            if (gCar.CombPlantFlag) {
                                                generateLabel('CombPlantFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('CombPlantFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('CombPlantFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating combined plant flag.');
                                    }
                                ).then(
                                    function () {
                                        generateLabel('StartDate', gCar.StartDate.substring(0, 10));
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating start date.');
                                    }
                                ).then(
                                    function () {
                                        generateLabel('EndDate', gCar.EndDate.substring(0, 10));
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating end date.');
                                    }
                                ).then(
                                    function () {
                                        try {
                                            var startDate = gCar.StartDate;
                                            var endDate = gCar.EndDate;
                                            if (startDate !== null && endDate !== null) {
                                                // if any date selected in datepicker
                                                var daysTotal = Date.daysBetween1(startDate, endDate);
                                                if (daysTotal == -1) {
                                                    generateLabel('numberOfDays', 'Invalid date range');
                                                }
                                                else {
                                                    generateLabel('numberOfDays', daysTotal + ' days');
                                                }
                                            }
                                        }
                                        catch (e) {
                                            console.log('Exception in populateCarDataReadOnly(): Failure calculating # of days.');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating # of days.');
                                    }
                                ).then(
                                    function () {
                                        generateLabel('FiscalYear', gCar.FiscalYear);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating fiscal year.');
                                    }
                                ).then(
                                    function () {
                                        generateLabel('BookDeprLife', gCar.BookDeprLife);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating depreciation life.');
                                    }
                                ).then(
                                    function () {
                                        // Populate the "BASIC INFO" tab, "CAPITAL PLAN STATEMENTS" section.
                                        // In Capital Plan?
                                        if (gCar.InCapPlanFlag != null) {
                                            if (gCar.InCapPlanFlag) {
                                                generateLabel('InCapPlanFlag', 'Yes');
                                                $('.toggleInCapPlan').css('display', 'none');
                                            }
                                            else {
                                                generateLabel('InCapPlanFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('InCapPlanFlag', 'N/A');
                                            $('.toggleInCapPlan').css('display', 'none');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating in capital plan flag.');
                                    }
                                ).then(
                                    function () {
                                        // Is it Expense Only?
                                        if (gCar.ExpenseOnlyFlag != null) {
                                            if (gCar.ExpenseOnlyFlag) {
                                                generateLabel('ExpenseOnlyFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('ExpenseOnlyFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('ExpenseOnlyFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating in capital plan flag.');
                                    }
                                ).then(
                                    function () {
                                        // Incremental to Capital Plan?
                                        if (gCar.IncCapPlanFlag != null) {
                                            if (gCar.IncCapPlanFlag) {
                                                generateLabel('IncCapPlanFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('IncCapPlanFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('IncCapPlanFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating incremental capital plan flag.');
                                    }
                                ).then(
                                    function () {
                                        // Capital Plan
                                        getCapitalPlanItem(gCar.CapitalPlanItemId);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating capital plan item.');
                                    }
                                ).then(
                                    function () {
                                        // Substitution?
                                        if (gCar.SubstitutionFlag != null) {
                                            if (gCar.SubstitutionFlag) {
                                                generateLabel('SubstitutionFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('SubstitutionFlag', 'No');
                                                $('.toggleSubstitution').css('display', 'none');
                                            }
                                        }
                                        else {
                                            generateLabel('SubstitutionFlag', 'N/A');
                                            $('.toggleSubstitution').css('display', 'none');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating substitution flag.');
                                    }
                                ).then(
                                    function () {
                                        // Substitution Project
                                        generateLabel('SubstitutionProject', gCar.SubstitutionProject);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating substitution project.');
                                    }
                                ).then(
                                    function () {
                                        // Assets affected (transferring, retiring, etc.) as part of this project?
                                        if (gCar.AssetsAffectedFlag != null) {
                                            if (gCar.AssetsAffectedFlag) {
                                                generateLabel('AssetsAffectedFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('AssetsAffectedFlag', 'No');
                                                $('.toggleAssetsAffected').css('display', 'none');
                                            }
                                        }
                                        else {
                                            generateLabel('AssetsAffectedFlag', 'N/A');
                                            $('.toggleAssetsAffected').css('display', 'none');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating assets affected flag.');
                                    }
                                ).then(
                                    function () {
                                        // Asset Write-Offs (Note: CTID Attachment Required) 
                                        generateLabel('AssetWriteOffs', gCar.AssetWriteOffs);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating assets write offs.');
                                    }
                                ).then(
                                    function () {
                                        // Were competitive bids received for this project?
                                        if (gCar.CompBidsFlag != null) {
                                            if (gCar.CompBidsFlag) {
                                                generateLabel('CompBidsFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('CompBidsFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('CompBidsFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating comp bids flag.');
                                    }
                                ).then(
                                    function () {
                                        // Is there a vendor contract(s)?
                                        if (gCar.VendorContractFlag != null) {
                                            if (gCar.VendorContractFlag) {
                                                generateLabel('VendorContractFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('VendorContractFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('VendorContractFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating vendor contract flag.');
                                    }
                                ).then(
                                    function () {
                                        // Does excess capacity exist elsewhere within Smithfield?
                                        if (gCar.ExcessCapacityFlag != null) {
                                            if (gCar.ExcessCapacityFlag) {
                                                generateLabel('ExcessCapacityFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('ExcessCapacityFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('ExcessCapacityFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating excess capacity flag.');
                                    }
                                ).then(
                                    function () {
                                        // Is this an expenditure for new technology?
                                        if (gCar.NewTechFlag != null) {
                                            if (gCar.NewTechFlag) {
                                                generateLabel('NewTechFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('NewTechFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('NewTechFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating new tech flag.');
                                    }
                                ).then(
                                    function () {
                                        // Will special maintenance skills need to be added?
                                        if (gCar.SpecMaintFlag != null) {
                                            if (gCar.SpecMaintFlag) {
                                                generateLabel('SpecMaintFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('SpecMaintFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('SpecMaintFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating special maintenance flag.');
                                    }
                                ).then(
                                    function () {
                                        // Will excess operating or maintenance expense be added?
                                        if (gCar.ExcessMaintFlag != null) {
                                            if (gCar.ExcessMaintFlag) {
                                                generateLabel('ExcessMaintFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('ExcessMaintFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('ExcessMaintFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating excess maintenance flag.');
                                    }
                                ).then(
                                    function () {
                                        // Populate the "BASIC INFO" tab, "LEASE DATA" section.
                                        // Is Lease Required?
                                        if (gCar.LeaseReqFlag != null) {
                                            if (gCar.LeaseReqFlag) {
                                                generateLabel('LeaseReqFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('LeaseReqFlag', 'No');
                                                $('.toggleLeaseReq').css('display', 'none');
                                            }
                                        }
                                        else {
                                            generateLabel('LeaseReqFlag', 'N/A');
                                            $('.toggleLeaseReq').css('display', 'none');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating lease required flag.');
                                    }
                                ).then(
                                    function () {
                                        // Will Smithfield own the item(s) at the end of the lease term?
                                        if (gCar.LeaseOwnFlag != null) {
                                            if (gCar.LeaseOwnFlag) {
                                                generateLabel('LeaseOwnFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('LeaseOwnFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('LeaseOwnFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating lease owner flag.');
                                    }
                                ).then(
                                    function () {
                                        // Does the lease contain a bargain purchase option?
                                        if (gCar.LeaseBargainOptionFlag != null) {
                                            if (gCar.LeaseBargainOptionFlag) {
                                                generateLabel('LeaseBargainOptionFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('LeaseBargainOptionFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('LeaseBargainOptionFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating lease bargain option flag.');
                                    }
                                ).then(
                                    function () {
                                        // Is NPV of the lease payments >= 90% of the FMV?
                                        if (gCar.LeaseNPVFlag != null) {
                                            if (gCar.LeaseNPVFlag) {
                                                generateLabel('LeaseNPVFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('LeaseNPVFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('LeaseNPVFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating lease NPV flag.');
                                    }
                                ).then(
                                    function () {
                                        // Economic Useful Life of the item (years)
                                        generateLabel('UsefulLifeYears', gCar.UsefulLifeYears);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating useful life years.');
                                    }
                                ).then(
                                    function () {
                                        // Lease Term (years)
                                        generateLabel('LeaseTermYears', gCar.LeaseTermYears);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating lease term years.');
                                    }
                                ).then(
                                    function () {
                                        // Lease to Economic Life Ratio
                                        var ratio = UpdateLeaseRatio();
                                        generateLabel('LeaseRatio', ratio);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating lease ratio.');
                                    }
                                ).then(
                                    function () {
                                        // Lease Type
                                        generateLabel('LeaseType', gCar.LeaseType);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating lease type.');
                                    }
                                ).then(
                                    function () {
                                        // Is this a Simple Payback?
                                        if (gCar.SimplePaybackFlag != null) {
                                            if (gCar.SimplePaybackFlag) {
                                                generateLabel('SimplePaybackFlag', 'Yes');
                                            }
                                            else {
                                                generateLabel('SimplePaybackFlag', 'No');
                                            }
                                        }
                                        else {
                                            generateLabel('SimplePaybackFlag', 'N/A');
                                        }
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating simple payback flag.');
                                    }
                                ).then(
                                    function () {
                                        // Populate the "DESCRIPTION" tab.
                                        //  generateLabel('ProjectDesc', removeTags(gCar.ProjectDesc));
                                        document.getElementById("ProjectDesc").innerHTML = gCar.ProjectDesc;
                                    },
                                    function () {
                                        console.log('Exception in CarForm3.aspx.populateCarDataReadOnly(): Failure in populating project description.');
                                    }
                                ).then(
                                    function () {
                                        document.getElementById("ProjectReason").innerHTML = gCar.ProjectReason;
                                        // generateLabel('ProjectReason', removeTags(gCar.ProjectReason));
                                    },
                                    function () {
                                        console.log('Exception in CarForm3.aspx.populateCarDataReadOnly(): Failure in populating project reason.');
                                    }
                                ).then(
                                    function() {
                                        document.getElementById("ProjectJustification").innerHTML =
                                            gCar.ProjectJustification;
                                        //generateLabel('ProjectJustification', removeTags(gCar.ProjectJustification));
                                    },
                                    function () {
                                        console.log('Exception in CarForm3.aspx.populateCarDataReadOnly(): Failure in populating project justification.');
                                    }
                                ).then(
                                    function () {
                                        populateCostSheetReadOnly();
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populateCostSheetReadOnly().');
                                    }
                                ).then(
                                    function () {
                                        populateFixedCostsReadOnly();
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populateFixedCostsReadOnly().');
                                    }
                                ).then(
                                    function () {
                                        populateForecastParameters();
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populateForecastParameters().');
                                    }
                                ).then(
                                    function () {
                                        // Populate the "SPEND FORECAST" tab.
                                        toggleAlertSpendForecastIsEmpty(gCarId);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populateForecastParameters().');
                                    }

                                ).then(
                                    function () {
                                        populateSpendForecastReadOnly();
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populateSpendForecastReadOnly().');
                                    }
                                ).then(
                                    function () {
                                        // Populate the "PAYBACK" tab.
                                        generateLabel('NPV', gCar.NPV);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating NPV summary.');
                                    }
                                ).then(
                                    function () {
                                        generateLabel('IRR', gCar.IRR);
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populating IRR.');
                                    }
                                ).then(
                                    function () {
                                        populatePaybackItemsReadOnly();
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populatePaybackItemsReadOnly().');
                                    }
                                ).then(
                                    function () {
                                        populateOngoingCostsReadOnly();
                                    },
                                    function () {
                                        console.log('Exception in CarForm3.aspx.populateCarDataReadOnly(): Failure in populateOngoingCostsReadOnly().');
                                    }
                                ).then(
                                    function () {
                                        populateWorkflow();
                                    },
                                    function () {
                                        console.log('In CarForm3.aspx.populateCarDataReadOnly(): Failure in populateWorkflow().');
                                    }
                                ).done(function () { lpSpinner.Hide(); }); //Turn off spinner
                            deferred.resolve();
                        }
                        catch (e) {
                            console.log('Exception in CarForm3.aspx.populateCarDataReadOnly():2: ' + e.message + ', ' + e.stack);
                        }
                    },
                    error: function (result) {
                        console.log('Exception in CarForm3.aspx.populateCarDataReadOnly():3: ERROR: GET CARMasters: ' + JSON.stringify(result));
                    },
                    timeout: 15000
                });
            } catch (e) {
                console.log('Exception in CarForm3.aspx.populateCarDataReadOnly():4: ' + e.message + ', ' + e.stack);
            }
            lpSpinner.Hide();
        };

        function populateCarDataNotReadOnly() {
            try {
                console.log('In CarForm3.aspx.populateCarDataNotReadOnly().');

                var deferred = $.Deferred();
                deferred
                    .then(
                        function () {
                            lpSpinner.Show();
                        },
                        function () {
                            console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in lpSpinner.Show()');
                        }
                    ).then(
                        function () {
                            populateProjectTypeDropDown();
                        },
                        function () {
                            console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateProjectTypeDropDown()');
                        }
                    ).then(
                        function () {
                            populateProjectManagerDropDown();
                        },
                        function () {
                            console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateProjectManagerDropDown()');
                        }
                    ).then(
                        function () {
                            populateProjectSponsorDropDown();
                        },
                        function () {
                            console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateProjectSponsorDropDown()');
                        }
                    ).then(
                        function () {
                            populateBookDepreciationLifeDropDown();
                        },
                        function () {
                            console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateBookDepreciationLifeDropDown()');
                        }
                    ).then(
                        function () {
                            populateCapitalPlanItemDropDown();
                        },
                        function () {
                            console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateCapitalPlanItemDropDown()');
                        }
                    ).then(
                        function () {
                            populateCurrencyTypeDropDown();
                        },
                        function () {
                            console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateCurrencyTypeDropDown()');
                        }
                    ).then(
                        function () {
                            populateUsefulLifeYearsDropDown();
                        },
                        function () {
                            console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateUsefulLifeYearsDropDown()');
                        }
                    ).then(
                        function () {
                            $.ajax({
                                url: operationUriPrefix + "odata/CARMasters?$filter=CARId eq " + gCarId,
                                dataType: "json",
                                success: function (result) {
                                    try {
                                        gCar = result.value[0];

                                        var deferred = $.Deferred();
                                        deferred
                                            .then(
                                                function () {
                                                    // Populate the Location Name
                                                    $.ajax({
                                                        url: operationUriPrefix + "odata/Orgs?$filter=OrgId eq '" + gCar.OrgId + "'",
                                                        dataType: "json"
                                                    }).done(function (result) {
                                                        try {
                                                            var Org = result.value[0];
                                                            ddeLocation.SetText(Org.OrgName);
                                                        } catch (e) {
                                                            console.log('Exception in populateCarDataNotReadOnly: ' + e.message + ', ' + e.stack);
                                                        }
                                                    });
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateProjectTypeDropDown()');
                                                }
                                            ).then(
                                                function () {
                                                    // Populate the Pillar Name
                                                    $.ajax({
                                                        url: operationUriPrefix + "odata/Pillars?$filter=PillarId eq '" + gCar.PillarId + "'",
                                                        dataType: "json"
                                                    }).done(function (result) {
                                                        try {
                                                            var Pillar = result.value[0];
                                                            //Populate the pillar dropdown
                                                            ddePillar.SetText(Pillar.Name);
                                                        } catch (e) {
                                                            console.log('Exception in populateCarDataNotReadOnly: ' + e.message + ', ' + e.stack);
                                                        }
                                                    });
                                                },
                                                function () {
                                                    console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating pillar.');
                                                }
                                            ).then(
                                                function () {
                                                    $('#lblProject').text(gCar.ProjectNumber + " - " + gCar.ProjectTitle);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateProjectManagerDropDown()');
                                                }
                                            ).then(
                                                function () {
                                                    $('#ProjectNumber').val(gCar.ProjectNumber);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating project number.');
                                                }
                                            ).then(
                                                function () {
                                                    $('#ProjectTitle').val(gCar.ProjectTitle);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating project title.');
                                                }
                                            ).then(
                                                function () {
                                                    $('#CostCenterNumber').val(gCar.CostCenterNumber);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating cost center number.');
                                                }
                                            ).then(
                                                function () {
                                                    $('#CostCenterDesc').val(gCar.CostCenterDesc);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating cost center description.');
                                                }
                                            ).then(
                                                function () {
                                                    $('#ExchangeRate').val(gCar.ExchangeRate);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating exchange rate.');
                                                }
                                            ).then(
                                                function () {
                                                    // Populate the "BASIC INFO" tab, "CAR DETAILS" section.
                                                    if (gCar.CombPlantFlag != null) {
                                                        if (gCar.CombPlantFlag) {
                                                            $('#CombPlantFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#CombPlantFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating combined plant flag.');
                                                }
                                            ).then(
                                                function () {
                                                    if (gCar.StartDate) {
                                                        $('#StartDate').val(gCar.StartDate.substring(0, 10));
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating start date.');
                                                }
                                            ).then(
                                                function () {
                                                    if (gCar.EndDate) {
                                                        $('#EndDate').val(gCar.EndDate.substring(0, 10));
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating end date.');
                                                }
                                            ).then(
                                                function () {
                                                    //Populate Audit radio button
                                                    if (gCar.AuditRequired != null)
                                                    {
                                                        if (gCar.AuditRequired)
                                                        {
                                                            $('#AuditRequired_Yes').prop('checked', true);
                                                            $('.toggleAuditRequired').css('display', 'block');
                                                        }
                                                        else {
                                                            $('#AuditRequired_No').prop('checked', true);
                                                            $('.toggleAuditRequired').css('display', 'none');
                                                        }
                                                    }
                                                    else
                                                    {
                                                        $('.toggleAuditRequired').css('display', 'none');
                                                    }

                                                    //Populate Audit Date
                                                    if (gCar.AuditDate) {
                                                        $('#AuditDate').val(gCar.AuditDate.substring(0, 10));
                                                    }
                                                },
                                                function () {
                                                    console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating audit date.');
                                                }
                                            ).then(
                                                function () {
                                                    if (gAllowAuditDataEntry == 'false') {
                                                        disableAuditFields(gCar.AuditDate);
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating # of days.');
                                                }
                                            ).then(
                                                function () {
                                                    try {
                                                        var startDate = $("#StartDate").datepicker('getDate');
                                                        var endDate = $("#EndDate").datepicker('getDate');
                                                        if (startDate !== null && endDate !== null) { // if any date selected in datepicker
                                                            var daysTotal = Date.daysBetween(startDate, endDate);
                                                            console.log('daysTotal: ' + daysTotal);
                                                            if (daysTotal == -1)
                                                                $('#numberOfDays').val('Invalid date range');
                                                            else
                                                                $('#numberOfDays').val(daysTotal + ' days');
                                                        }
                                                    }
                                                    catch (e) {
                                                        console.log('Exception in populateCarDataNotReadOnly(): Failure calculating # of days.');
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating # of days.');
                                                }
                                            ).then(
                                                function () {
                                                    // Populate the "BASIC INFO" tab, "CAPITAL PLAN STATEMENTS" section.
                                                    // In Capital Plan?
                                                    if (gCar.InCapPlanFlag != null) {
                                                        if (gCar.InCapPlanFlag) {
                                                            $('#InCapPlanFlag_Yes').prop('checked', true);
                                                            $('.toggleInCapPlan').css('display', 'none');
                                                        }
                                                        else {
                                                            $('#InCapPlanFlag_No').prop('checked', true);
                                                            $('.toggleInCapPlan').css('display', 'block');
                                                        }
                                                    }
                                                    else {
                                                        $('.toggleInCapPlan').css('display', 'none');
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating in capital plan flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Is it Expense Only?
                                                    if (gCar.ExpenseOnlyFlag != null) {
                                                        if (gCar.ExpenseOnlyFlag) {
                                                            $('#ExpenseOnlyFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#ExpenseOnlyFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating is expense only flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Incremental to Capital Plan?
                                                    if (gCar.IncCapPlanFlag != null) {
                                                        if (gCar.IncCapPlanFlag) {
                                                            $('#IncCapPlanFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#IncCapPlanFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating incremental capital plan flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Substitution?
                                                    if (gCar.SubstitutionFlag != null) {
                                                        if (gCar.SubstitutionFlag) {
                                                            $('#SubstitutionFlag_Yes').prop('checked', true);
                                                            $('.toggleSubstitution').css('display', 'block');
                                                        }
                                                        else {
                                                            $('#SubstitutionFlag_No').prop('checked', true);
                                                            $('.toggleSubstitution').css('display', 'none');
                                                        }
                                                    }
                                                    else {
                                                        $('.toggleSubstitution').css('display', 'none');
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating substitution flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Substitution Project
                                                    $('#SubstitutionProject').val(gCar.SubstitutionProject).prop('readOnly', false);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating substitution project.');
                                                }
                                            ).then(
                                                function () {

                                                    // Assets affected (transferring, retiring, etc.) as part of this project?
                                                    if (gCar.AssetsAffectedFlag != null) {
                                                        if (gCar.AssetsAffectedFlag) {
                                                            $('#AssetsAffectedFlag_Yes').prop('checked', true);
                                                            $('.toggleAssetsAffected').css('display', 'block');
                                                        }
                                                        else {
                                                            $('#AssetsAffectedFlag_No').prop('checked', true);
                                                            $('.toggleAssetsAffected').css('display', 'none');
                                                        }
                                                    }
                                                    else {
                                                        $('.toggleAssetsAffected').css('display', 'none');
                                                    }

                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating assets affected flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Asset Write-Offs (Note: CTID Attachment Required) 
                                                    $('#AssetWriteOffs').val(gCar.AssetWriteOffs).prop('readOnly', false);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating asset write offs.');
                                                }
                                            ).then(
                                                function () {
                                                    // Were competitive bids received for this project?
                                                    if (gCar.CompBidsFlag != null) {
                                                        if (gCar.CompBidsFlag) {
                                                            $('#CompBidsFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#CompBidsFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating comp bid flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Is there a vendor contract(s)?
                                                    if (gCar.VendorContractFlag != null) {
                                                        if (gCar.VendorContractFlag) {
                                                            $('#VendorContractFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#VendorContractFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating vendor contract flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Does excess capacity exist elsewhere within Smithfield?
                                                    if (gCar.ExcessCapacityFlag != null) {
                                                        if (gCar.ExcessCapacityFlag) {
                                                            $('#ExcessCapacityFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#ExcessCapacityFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating excess capacity flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Is this an expenditure for new technology?
                                                    if (gCar.NewTechFlag != null) {
                                                        if (gCar.NewTechFlag) {
                                                            $('#NewTechFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#NewTechFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating new tech flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Will special maintenance skills need to be added?
                                                    if (gCar.SpecMaintFlag != null) {
                                                        if (gCar.SpecMaintFlag) {
                                                            $('#SpecMaintFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#SpecMaintFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating special maintenance flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Will excess operating or maintenance expense be added?
                                                    if (gCar.ExcessMaintFlag != null) {
                                                        if (gCar.ExcessMaintFlag) {
                                                            $('#ExcessMaintFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#ExcessMaintFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating excess maintenance flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Populate the "BASIC INFO" tab, "LEASE DATA" section.
                                                    if (gCar.LeaseReqFlag != null) {
                                                        if (gCar.LeaseReqFlag) {
                                                            $('#LeaseReqFlag_Yes').prop('checked', true);
                                                            $('.toggleLeaseReq').css('display', 'block');
                                                        }
                                                        else {
                                                            $('#LeaseReqFlag_No').prop('checked', true);
                                                            $('.toggleLeaseReq').css('display', 'none');
                                                        }
                                                    }
                                                    else {
                                                        $('.toggleLeaseReq').css('display', 'none');
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating lease required flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Is this a Simple Payback?
                                                    if (gCar.SimplePaybackFlag != null) {
                                                        if (gCar.SimplePaybackFlag) {
                                                            $('#SimplePaybackFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#SimplePaybackFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating simple payback flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Will Smithfield own the item(s) at the end of the lease term?
                                                    if (gCar.LeaseOwnFlag != null) {
                                                        if (gCar.LeaseOwnFlag) {
                                                            $('#LeaseOwnFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#LeaseOwnFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating lease own flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Does the lease contain a bargain purchase option?
                                                    if (gCar.LeaseBargainOptionFlag != null) {
                                                        if (gCar.LeaseBargainOptionFlag) {
                                                            $('#LeaseBargainOptionFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#LeaseBargainOptionFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating lease bargain option flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Fiscal Year
                                                    $('#FiscalYear').val(gCar.FiscalYear);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating fiscal year.');
                                                }
                                            ).then(
                                                function () {
                                                    // Economic Useful Life of the item (years)
                                                    var tempUsefulLifeYears = (gCar.UsefulLifeYears) ? gCar.UsefulLifeYears : "3";
                                                    $('#UsefulLifeYears').val(tempUsefulLifeYears);
                                                    $("#UsefulLifeYears").selectmenu("refresh");
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating useful life years.');
                                                }
                                            ).then(
                                                function () {
                                                    // Lease Term (years)
                                                    $('#LeaseTermYears').val(gCar.LeaseTermYears);
                                                },
                                                function () {
                                                    //lpSpinner.Hide();
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating lease term years.');
                                                }
                                            ).then(
                                                function () {
                                                    // Lease to Economic Life Ratio
                                                    LeaseRatio_OnChange();
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating lease ratio.');
                                                }
                                            ).then(
                                                function () {
                                                    // Is NPV of the lease payments >= 90% of the FMV?
                                                    if (gCar.LeaseNPVFlag != null) {
                                                        if (gCar.LeaseNPVFlag) {
                                                            $('#LeaseNPVFlag_Yes').prop('checked', true);
                                                        }
                                                        else {
                                                            $('#LeaseNPVFlag_No').prop('checked', true);
                                                        }
                                                    }
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating lease NPV flag.');
                                                }
                                            ).then(
                                                function () {
                                                    // Lease Type
                                                    $('#LeaseType').val(gCar.LeaseType);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating lease type.');
                                                }
                                            ).then(
                                                function () {
                                                    // Populate the "DESCRIPTION" tab.
                                                    projectDescEditor.root.innerHTML = gCar.ProjectDesc;
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating project description.');
                                                }
                                            ).then(
                                                function () {
                                                    projectReasonEditor.root.innerHTML = gCar.ProjectReason;
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating project reason.');
                                                }
                                            ).then(
                                                function () {
                                                    projectJustificationEditor.root.innerHTML = gCar.ProjectJustification;
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating project justification.');
                                                }
                                            ).then(
                                                function () {
                                                    $("#NPV").val(gCar.NPV);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating NPV summary.');
                                                }
                                            ).then(
                                                function () {
                                                    $("#IRR").val(gCar.IRR);
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating IRR.');
                                                }
                                            ).then(
                                                function () {
                                                    // Populate the dropdowns
                                                    $('#ProjectTypeId').val(gCar.ProjectTypeId);
                                                    $('#ProjectTypeId').selectmenu("refresh");
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating project type.');
                                                }
                                            ).then(
                                                function () {
                                                    $('#ProjSponsorId').val(gCar.ProjSponsorId);
                                                    $('#ProjSponsorId').selectmenu("refresh");
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating project sponsor.');
                                                }
                                            ).then(
                                                function () {
                                                    $('#ProjManagerId').val(gCar.ProjManagerId);
                                                    $('#ProjManagerId').selectmenu("refresh");
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating project manager.');
                                                }
                                            ).then(
                                                function () {
                                                    $('#CurrencyTypeId').val((gCar.CurrencyTypeId) ? gCar.CurrencyTypeId : 1);
                                                    $('#CurrencyTypeId').selectmenu("refresh");
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating currency type.');
                                                }
                                            ).then(
                                                function () {
                                                    $('#BookDeprLife').val(gCar.BookDeprLife);
                                                    $('#BookDeprLife').selectmenu("refresh");
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating depreciation life.');
                                                }
                                            ).then(
                                                function () {
                                                    $('#CapitalPlanItemId').val(gCar.CapitalPlanItemId);
                                                    $('#CapitalPlanItemId').selectmenu("refresh");
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating capital plan item.');
                                                }
                                            ).then(
                                                function () {
                                                    $('#UsefulLifeYears').val(gCar.UsefulLifeYears);
                                                    $('#UsefulLifeYears').selectmenu("refresh");
                                                },
                                                function () {
                                                    console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populating useful life years.');
                                                }
                                            );
                                        deferred.resolve();
                                    } catch (e) {
                                        lpSpinner.Hide();
                                        console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly():2: ' + e.message + ', ' + e.stack);
                                    }
                                },
                                error: function (result) {
                                    lpSpinner.Hide();
                                    console.log('ERROR: GET CARMasters: ' + JSON.stringify(result));
                                },
                                timeout: 15000
                            });
                        },
                        function () {
                            console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateCarDataNotReadOnly()');
                        }
                    ).then(
                        function () {
                            $("#StartDate").datepicker({
                                changeMonth: true,
                                changeYear: true,
                                firstDay: 1,
                                dateFormat: "yy-mm-dd",
                                showButtonPanel: true
                            });
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in setting start, end and audit dates.');
                        }
                    ).then(
                        function () {
                            $("#EndDate").datepicker({
                                changeMonth: true,
                                changeYear: true,
                                firstDay: 1,
                                dateFormat: "yy-mm-dd",
                                showButtonPanel: true
                            });
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in setting start, end and audit dates.');
                        }
                    ).then(
                        function () {
                            $("#AuditDate").datepicker({
                                changeMonth: true,
                                changeYear: true,
                                firstDay: 1,
                                dateFormat: "yy-mm-dd",
                                showButtonPanel: true
                            });
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in setting start, end and audit dates.');
                        }
                    ).then(
                        function () {
                            populateCostSheetNotReadOnly();
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateCostSheetNotReadOnly().');
                        }
                    ).then(
                        function () {
                            populateFixedCostsNotReadOnly();
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateFixedCostsNotReadOnly().');
                        }
                    ).then(
                        function () {
                            // Populate the "SPEND FORECAST" tab.
                            populateForecastParameters();
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateForecastParameters().');
                        }
                    ).then(
                        function () {
                            // Populate the "SPEND FORECAST" tab.
                            toggleAlertSpendForecastIsEmpty(gCarId);
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateForecastParameters().');
                        }
                    ).then(
                        function () {
                            populateSpendForecastNotReadOnly();
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateSpendForecastNotReadOnly().');
                        }
                    ).then(
                        function () {
                            // Populate the "PAYBACK" tab.
                            populatePaybackItemsNotReadOnly();
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populatePaybackItemsNotReadOnly().');
                        }
                    ).then(
                        function () {
                            populateOngoingCostsNotReadOnly();
                        },
                        function () {
                            console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly(): Failure in "DESCRIPTION"/"SPEND FORECAST"/"PAYBACK" tabs');
                        }
                    ).then(
                        function () {
                            populateWorkflow();
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateWorkflow().');
                        }
                    ).then(
                        function () {
                            if (TabsEnabled != "true") {
                                disableAllTabs();
                            }
                        },
                        function () {
                            console.log('In CarForm3.aspx.populateCarDataNotReadOnly(): Failure in populateWorkflow().');
                        }
                    ).done(function () { lpSpinner.Hide(); }); //Turn off spinner
                deferred.resolve();
            }
            catch (e) {
                lpSpinner.Hide();
                console.log('Exception in CarForm3.aspx.populateCarDataNotReadOnly():3: ' + e.message + ', ' + e.stack);
            }
        };

        function AreRequiredFieldsCompleted() {
            try {
                console.log('In CarForm3.aspx.AreRequiredFieldsCompleted().');

                $.ajax({
                    url: operationUriPrefix + "odata/vWorklists?$filter=CARId eq " + gCarId,
                    dataType: "json",
                    contentType: "application/json"
                }).done(function (result) {
                    var wlResult = result.value[0];

                    //Only run if the CAR is in Create mode!
                    if (wlResult.CurStepName == "Create") {
                        var hasProjTitle = $('#ProjectTitle').val().length > 0;
                        var hasOrgId = ddeLocation.GetText().length > 0;
                        var hasProjManagerId = $('#ProjManagerId').val().length > 0;
                        var hasCostCenterNumber = $('#CostCenterNumber').val().length > 0;
                        var hasCurrencyTypeId = $('#CurrencyTypeId').val().length > 0;
                        var hasProjTypeId = $('#ProjectTypeId').val().length > 0;
                        var hasPillarId = ddePillar.GetText().length > 0;
                        var hasStartDate = $('#StartDate').val().length > 0;
                        var hasEndDate = $('#EndDate').val().length > 0;
                        var hasInCapPlanFlag = $('input[name=InCapitalPlanFlag]:checked').prop('checked');
                        var hasSubstitutionFlag = $('input[name=SubstitutionFlag]:checked').prop('checked');
                        var hasAssetsAffectedFlag = $('input[name=AssetsAffectedFlag]:checked').prop('checked');
                        var hasCompBidsFlag = $('input[name=CompBidsFlag]:checked').prop('checked');
                        var hasVendorContractFlag = $('input[name=VendorContractFlag]:checked').prop('checked');
                        var hasExcessCapacityFlag = $('input[name=ExcessCapacityFlag]:checked').prop('checked');
                        var hasSpecMaintFlag = $('input[name=SpecMaintFlag]:checked').prop('checked');
                        var hasExcessMaintFlag = $('input[name=ExcessMaintFlag]:checked').prop('checked');
                        var hasLeaseReqFlag = $('input[name=LeaseReqFlag]:checked').prop('checked');
                        var hasSimplePaybackFlag = $('input[name=SimplePaybackFlag]:checked').prop('checked');

                        //If Lease is Required, then check other required fields, otherwise pass them
                        var isLeaseReq = $('input[name=LeaseReqFlag]:checked').val() === "Yes";
                        var hasLeaseOwnFlag = (isLeaseReq) ? $('input[name=LeaseOwnFlag]:checked').prop('checked') : true;
                        var hasLeaseBargainOptionFlag = (isLeaseReq) ? $('input[name=LeaseBargainOptionFlag]:checked').prop('checked') : true;
                        var hasLeaseNPVFlag = (isLeaseReq) ? $('input[name=LeaseNPVFlag]:checked').prop('checked') : true;

                        //Are all required fields completed?
                        if (hasOrgId && hasProjTitle && hasProjManagerId && hasCostCenterNumber && hasProjTypeId && hasCurrencyTypeId
                            && hasPillarId && hasStartDate && hasEndDate && hasInCapPlanFlag && hasSubstitutionFlag && hasAssetsAffectedFlag
                            && hasCompBidsFlag && hasVendorContractFlag && hasExcessCapacityFlag && hasSpecMaintFlag && hasExcessMaintFlag
                            && hasLeaseReqFlag && hasSimplePaybackFlag && hasLeaseOwnFlag && hasLeaseBargainOptionFlag && hasLeaseNPVFlag) 
                        {
                            enableAllTabs();
                        }
                        else {
                            disableAllTabs();
                        }
                    }
                }).fail(function (data) {
                    var msg;
                    if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                        msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                    } else {
                        msg = JSON.stringify(data);
                    }
                    alert('Exception in CarForm3.aspx.AreRequiredFieldsCompleted(): ' + msg);
                    console.log('Exception in CarForm3.aspx.AreRequiredFieldsCompleted(): ' + JSON.stringify(data));
                });
            }
            catch (e) {
                //lpSpinner.Hide();
                console.log('Exception in CarForm3.aspx.AreRequiredFieldsCompleted() ' + e.message + ', ' + e.stack);
            }
        };

        function populatePaybackItemsNotReadOnly() {
            try {
                console.log('In CarForm3.aspx.populatePaybackItemsNotReadOnly().');

                var paybackItems = new DevExpress.data.CustomStore({
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;
                        $.ajax({
                            url: operationUriPrefix + "odata/vPaybacks?$filter=CARId eq " + gCarId + " and PaybackFlag eq true",
                            dataType: "json",
                            contentType: "application/json"
                        }).done(function (result) {
                            console.log('In CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.load: ' + JSON.stringify(result.value));

                            deferred.resolve(result.value, {});
                        }).fail(function (data) {
                            //lpSpinner.Hide();
                            var msg;
                            if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                            } else {
                                msg = JSON.stringify(data);
                            }
                            alert('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.load: ' + msg);
                            console.log('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.load: ' + JSON.stringify(data));
                        });
                        return deferred.promise();
                    },
                    insert: function (values) {
                        lpSpinner.SetText('Adding to the Payback Items...');
                        //lpSpinner.Show();
                        console.log('In CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.insert: values: ' + JSON.stringify(values)); // eg: values: {"__KEY__":"96559962-1911-8948-e967-efd82053c790","Quantity":3,"Category":"B","Descr":"reedwqdasfda","Capital":334}
                        if (values) { // Just checking if we need to save anything.
                            var columnNames = Object.keys(values); // Get the column/field names so we can decide how to save things below...
                            console.log('Object.keys(values): columnNames: ' + columnNames);
                            // 
                            // Now we get all of the changed values for the months, and save them to the database.
                            //
                            delete values["__KEY__"]; // This removes it from values.
                            var createTime = new Date();
                            var json = { "CARId": gCarId };
                            $.extend(json, values); // Merge the newly saved values back to the global CAR object, gCar so that it reflects the contents of the datbase.

                            console.log('In CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.insert: getting ready to send to DB. json: ' + JSON.stringify(json));
                            // We have it!!!! Update the database
                            //lpSpinner.Show();
                            $.ajax({
                                url: operationUriPrefix + "odata/PaybackItems",
                                dataType: "json",
                                contentType: "application/json",
                                type: "Post",
                                data: JSON.stringify(json)
                            }).done(function (result2) {
                                try {
                                    console.log('In CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.insert: Successfully updated DB using (' + JSON.stringify(values) + '): result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                    $("#jsGridPaybackItems").dxDataGrid("instance").refresh();
                                    //lpSpinner.Hide();
                                } catch (e) {
                                    //lpSpinner.Hide();
                                    console.log('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.insert: ' + e.message + ', ' + e.stack);
                                }
                            }).fail(function (data) {
                                //lpSpinner.Hide();
                                var msg;
                                if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                    msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                } else {
                                    msg = JSON.stringify(data);
                                }
                                alert('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.fail: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                console.log('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.fail: ' + JSON.stringify(data));
                                //lpSpinner.Hide();
                            });
                        } else {
                            //lpSpinner.Hide();
                            console.log('There was nothing to save back to the database.');
                            alert('There was nothing to save back to the database.');
                        }
                    },
                    update: function (keys, values) {
                        lpSpinner.SetText('Updating the Fixed Costs...');
                        //lpSpinner.Show();
                        console.log('In CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.update: keys: ' + JSON.stringify(keys) + ', values: ' + JSON.stringify(values)); // eg: yyyyyyyyyyyyyyyyyyyyyyyyyy values: {"July 2019":7777}
                        if (keys && values) { // Just checking if we need to save anything.
                            var columnNames = Object.keys(values); // Get the column/field names so we can decide how to save things below...
                            console.log('Object.keys(values): columnNames: ' + columnNames);
                            var paybackItem = keys; // The "CostSheetId" value.
                            var paybackId = paybackItem.PaybackId;
                            // 
                            // Now we get all of the changed values for the months, and save them to the database.
                            //
                            console.log('In CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.update: getting ready to send to DB. paybackId: ' + paybackId + ', values: ' + JSON.stringify(values));
                            // We have it!!!! Update the database
                            lpSpinner.SetText('Saving...');
                            //lpSpinner.Show();
                            $.ajax({
                                url: operationUriPrefix + "odata/PaybackItems(" + paybackId + ")",
                                dataType: "json",
                                contentType: "application/json",
                                type: "Patch",
                                data: JSON.stringify(values)
                            }).done(function (result2) {
                                try {
                                    if (result2) {
                                        //lpSpinner.Hide();
                                        alert('Error saving: ' + result2 + ', ' + JSON.stringify(result2));
                                    } else {
                                        console.log('In CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.update: Successfully updated DB using (' + JSON.stringify(values) + '): result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                        $("#jsGridPaybackItems").dxDataGrid("instance").refresh();
                                        //lpSpinner.Hide();
                                    }
                                } catch (e) {
                                    //lpSpinner.Hide();
                                    console.log('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.update: ' + e.message + ', ' + e.stack);
                                }
                            }).fail(function (data) {
                                //lpSpinner.Hide();
                                var msg;
                                if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                    msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                } else {
                                    msg = JSON.stringify(data);
                                }
                                alert('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.update: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                console.log('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.update: ' + JSON.stringify(data));
                            });
                        } else {
                            //lpSpinner.Hide();
                            console.log('There was nothing to save back to the database.');
                        }
                    },
                    remove: function (result) {
                        console.log('REMOVE: result: ' + JSON.stringify(result));
                        var paybackId = result.PaybackId;
                        //
                        // This is where we delete from PaybackItem table.
                        //
                        $.ajax({
                            url: operationUriPrefix + "odata/PaybackItems(" + paybackId + ")",
                            dataType: "json",
                            contentType: "application/json",
                            type: "Delete"
                        }).done(function (result2) {
                            try {
                                if (result2) {
                                    //lpSpinner.Hide();
                                    alert('Error deleting: ' + result2 + ', ' + JSON.stringify(result2));
                                } else {
                                    console.log('In CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.delete: Successfully deleted from DB. result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                    $("#jsGridPaybackItems").dxDataGrid("instance").refresh();
                                    //$("#jsGridSpendForecastSummary").dxDataGrid("instance").refresh();
                                    //lpSpinner.Hide();
                                }
                            } catch (e) {
                                //lpSpinner.Hide();
                                console.log('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.delete: ' + e.message + ', ' + e.stack);
                            }
                        }).fail(function (data) {
                            //lpSpinner.Hide();
                            var msg;
                            if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                            }
                            else {
                                msg = JSON.stringify(data);
                            }
                            alert('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.delete: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                            console.log('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.delete: ' + JSON.stringify(data));
                            //var error = JSON.parse(data.responseText)["odata.error"];

                            //lpSpinner.Hide();
                            //console.log('Fail in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.fail: ' + JSON.stringify(data));
                            //var error = JSON.parse(data.responseText)["odata.error"];
                            //alert('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItems.fail: ' + error.message.value + ' ' + error.innererror.message); // + ', EntityValidationErrors: ' + data.EntityValidationErrors);
                        });
                    }
                });



                $.ajax({
                    url: operationUriPrefix + "odata/PaybackTypes?$filter=PaybackFlag eq true&$orderby=Name asc",
                    dataType: "json",
                    contentType: "application/json"
                }).done(function (result) {
                    var paybackItemTypes = result.value;
                    console.log('In CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItemTypes.load: paybackItemTypes: ' + JSON.stringify(paybackItemTypes));


                    $("#jsGridPaybackItems").dxDataGrid({
                        dataSource: {
                            store: paybackItems
                        },
                        loadPanel: {
                            enabled: false
                        },
                        cacheEnabled: true,
                        editing: {
                            allowUpdating: true,
                            allowDeleting: true,
                            allowAdding: true
                        },
                        paging: {
                            pageSize: 25
                        },
                        pager: {
                            showPageSizeSelector: true,
                            allowedPageSizes: [10, 25, 50, 100, 5000]
                        },
                        remoteOperations: false,
                        searchPanel: {
                            visible: false
                        },
                        allowColumnReordering: false,
                        allowColumnResizing: false,
                        rowAlternationEnabled: false,
                        showBorders: true,
                        filterRow: { visible: false },
                        columns: [
                            {
                                dataField: "PaybackTypeId",
                                caption: "Payback Type",
                                dataType: "string",
                                width: '25%',
                                lookup: {
                                    dataSource: paybackItemTypes,
                                    valueExpr: "PaybackTypeId",
                                    displayExpr: "Name"
                                },
                                validationRules: [{ type: "required" }]
                            },
                            {
                                dataField: "Amount",
                                caption: "Savings $ Per Year",
                                dataType: "number",
                                format: { type: "currency", precision: 0 },
                                width: '15%',
                                validationRules: [{ type: "required" }]
                            },
                            {
                                dataField: "Comments",
                                caption: "Comments",
                                dataType: "string",
                                width: '60%'
                            }
                        ],
                        summary: {
                            totalItems: [{
                                column: "PaybackTypeId",
                                alignment: "left",
                                displayFormat: "Total"
                            },
                            {
                                column: "Amount",
                                summaryType: "sum",
                                alignment: "right",
                                valueFormat: "currency",
                                displayFormat: "{0}"
                            }]
                        },
                        onKeyDown: function (e) {
                            if (e.event.keyCode == 13 || e.event.keyCode == 190 || e.event.keyCode == 110)
                            {
                                console.log("Payback: Enter/Decimal/Period buttons disabled.");
                                e.event.preventDefault();
                                return false;
                            }
                        },
                        onEditorPreparing: function (e) {
                            //Added fix for backspace prevention (only when there is a value)
                            if (e.parentType == "dataRow") {
                                e.editorOptions.onKeyDown = function (arg) {
                                    var value = e.element.find("input").val();
                                    if (arg.event.keyCode == 8) {
                                        if (e.editorName === "dxSelectBox" || value.length < 1) {
                                            arg.event.preventDefault();
                                            arg.event.stopPropagation();
                                        }
                                    }
                                }
                            }
                        },
                        onCellPrepared: function (e) {
                            if (e.rowType == "totalFooter") {
                                e.cellElement.css({ "font-style": "italic", "font-weight": "bold" });
                            }
                        }
                    });
                }).fail(function (data) {
                    //lpSpinner.Hide();
                    var msg;
                    if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                        msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                    }
                    else {
                        msg = JSON.stringify(data);
                    }
                    alert('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItemTypes.load: ' + msg);
                    console.log('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly().paybackItemTypes.load: ' + JSON.stringify(data));
                });
            } catch (e) {
                console.log('Exception in CarForm3.aspx.populatePaybackItemsNotReadOnly(): ' + e.message + ', ' + e.stack);
            }
        };

        function populatePaybackItemsReadOnly() {
            try {
                console.log('In CarForm3.aspx.populatePaybackItemsReadOnly().');

                var paybackItems = new DevExpress.data.CustomStore({
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;
                        $.ajax({
                            url: operationUriPrefix + "odata/vPaybacks?$filter=CARId eq " + gCarId + " and PaybackFlag eq true",
                            dataType: "json",
                            contentType: "application/json"
                        }).done(function (result) {
                            deferred.resolve(result.value, {});
                        }).fail(function (data) {
                            //lpSpinner.Hide();
                            var msg;
                            if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                            } else {
                                msg = JSON.stringify(data);
                            }
                            //alert('Exception in CarForm3.aspx.populatePaybackItemsReadOnly().paybackItems.load: ' + msg);
                            console.log('Exception in CarForm3.aspx.populatePaybackItemsReadOnly().paybackItems.load: ' + JSON.stringify(data));
                        });
                        return deferred.promise();
                    }
                });

                $("#jsGridPaybackItems").dxDataGrid({
                    dataSource: {
                        store: paybackItems
                    },
                    loadPanel: {
                        enabled: false
                    },
                    cacheEnabled: true,
                    editing: {
                        mode: "row",
                        allowUpdating: false,
                        allowDeleting: false,
                        allowAdding: false
                    },
                    paging: {
                        pageSize: 25
                    },
                    pager: {
                        showPageSizeSelector: true,
                        allowedPageSizes: [10, 25, 50, 100, 5000]
                    },
                    remoteOperations: false,
                    searchPanel: {
                        visible: false
                    },
                    allowColumnReordering: false,
                    allowColumnResizing: false,
                    rowAlternationEnabled: false,
                    showBorders: true,
                    filterRow: { visible: false },
                    columns: [
                        {
                            dataField: "Name",
                            caption: "Payback Type",
                            dataType: "string",
                            width: '25%'
                        },
                        {
                            dataField: "Amount",
                            caption: "Savings $ Per Year",
                            dataType: "number",
                            format: { type: "currency", precision: 0 },
                            width: '15%'
                        },
                        {
                            dataField: "Comments",
                            caption: "Comments",
                            dataType: "string",
                            width: '60%'
                        }
                    ],
                    summary: {
                        totalItems: [{
                            column: "Name",
                            alignment: "left",
                            displayFormat: "Total"
                        },
                        {
                            column: "Amount",
                            summaryType: "sum",
                            alignment: "right",
                            valueFormat: "currency",
                            displayFormat: "{0}"
                        }]
                    },
                    onCellPrepared: function (e) {
                        if (e.rowType == "totalFooter") {
                            e.cellElement.css({ "font-style": "italic", "font-weight": "bold" });
                        }
                    }
                });
            } catch (e) {
                console.log('Exception in CarForm3.aspx.populatePaybackItemsReadOnly(): ' + e.message + ', ' + e.stack);
            }
        };

        function populateOngoingCostsNotReadOnly() {
            try {
                console.log('In CarForm3.aspx.populateOngoingCostsNotReadOnly().');

                var paybackItems = new DevExpress.data.CustomStore({
                    load: function (loadOptions)
                    {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;
                        $.ajax({
                            url: operationUriPrefix + "odata/vPaybacks?$filter=CARId eq " + gCarId + " and PaybackFlag eq false",
                            dataType: "json",
                            contentType: "application/json"
                        }).done(function (result) {
                            deferred.resolve(result.value, {});
                        }).fail(function (data) {
                            //lpSpinner.Hide();
                            var msg;
                            if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                            } else {
                                msg = JSON.stringify(data);
                            }
                            //alert('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.load: ' + msg);
                            console.log('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.load: ' + JSON.stringify(data));
                        });
                        return deferred.promise();
                    },
                    insert: function (values) {
                        lpSpinner.SetText('Adding to the Payback Items...');
                        //lpSpinner.Show();
                        console.log('In CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.insert: values: ' + JSON.stringify(values)); // eg: values: {"__KEY__":"96559962-1911-8948-e967-efd82053c790","Quantity":3,"Category":"B","Descr":"reedwqdasfda","Capital":334}
                        if (values) { // Just checking if we need to save anything.
                            var columnNames = Object.keys(values); // Get the column/field names so we can decide how to save things below...
                            console.log('Object.keys(values): columnNames: ' + columnNames);
                            // 
                            // Now we get all of the changed values for the months, and save them to the database.
                            //
                            delete values["__KEY__"]; // This removes it from values.
                            var createTime = new Date();
                            var json = { "CARId": gCarId };
                            $.extend(json, values); // Merge the newly saved values back to the global CAR object, gCar so that it reflects the contents of the datbase.

                            console.log('In CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.insert: getting ready to send to DB. json: ' + JSON.stringify(json));
                            // We have it!!!! Update the database
                            //lpSpinner.Show();
                            $.ajax({
                                url: operationUriPrefix + "odata/PaybackItems",
                                dataType: "json",
                                contentType: "application/json",
                                type: "Post",
                                data: JSON.stringify(json)
                            }).done(function (result2) {
                                try {
                                    console.log('In CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.insert: Successfully updated DB using (' + JSON.stringify(values) + '): result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                    $("#jsGridOngoingCosts").dxDataGrid("instance").refresh();
                                    //lpSpinner.Hide();
                                } catch (e) {
                                    //lpSpinner.Hide();
                                    console.log('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.insert: ' + e.message + ', ' + e.stack);
                                }
                            }).fail(function (data) {
                                //lpSpinner.Hide();
                                var msg;
                                if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                    msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                } else {
                                    msg = JSON.stringify(data);
                                }
                                //alert('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.insert: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                console.log('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.insert: ' + JSON.stringify(data));
                                //var error = JSON.parse(data.responseText)["odata.error"];
                            });
                        } else {
                            //lpSpinner.Hide();
                            console.log('There was nothing to save back to the database.');
                            alert('There was nothing to save back to the database.');
                        }
                    },
                    update: function (keys, values) {
                        lpSpinner.SetText('Updating the Fixed Costs...');
                        //lpSpinner.Show();

                        console.log('In CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.update: keys: ' + JSON.stringify(keys) + ', values: ' + JSON.stringify(values)); // eg: yyyyyyyyyyyyyyyyyyyyyyyyyy values: {"July 2019":7777}
                        if (keys && values) { // Just checking if we need to save anything.
                            var columnNames = Object.keys(values); // Get the column/field names so we can decide how to save things below...
                            console.log('Object.keys(values): columnNames: ' + columnNames);
                            var paybackItem = keys; // The "CostSheetId" value.
                            var paybackId = paybackItem.PaybackId;
                            // 
                            // Now we get all of the changed values for the months, and save them to the database.
                            //
                            console.log('In CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.update: getting ready to send to DB. paybackId: ' + paybackId + ', values: ' + JSON.stringify(values));
                            // We have it!!!! Update the database
                            lpSpinner.SetText('Saving...');
                            //lpSpinner.Show();
                            $.ajax({
                                url: operationUriPrefix + "odata/PaybackItems(" + paybackId + ")",
                                dataType: "json",
                                contentType: "application/json",
                                type: "Patch",
                                data: JSON.stringify(values)
                            }).done(function (result2) {
                                try {
                                    if (result2) {
                                        //lpSpinner.Hide();
                                        alert('Error saving: ' + result2 + ', ' + JSON.stringify(result2));
                                    } else {
                                        console.log('In CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.update: Successfully updated DB using (' + JSON.stringify(values) + '): result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                        $("#jsGridOngoingCosts").dxDataGrid("instance").refresh();
                                        //lpSpinner.Hide();
                                    }
                                } catch (e) {
                                    //lpSpinner.Hide();
                                    console.log('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.update: ' + e.message + ', ' + e.stack);
                                }
                            }).fail(function (data) {
                                //lpSpinner.Hide();
                                var msg;
                                if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                    msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                                } else {
                                    msg = JSON.stringify(data);
                                }
                                //alert('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.update: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                                console.log('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.update: ' + JSON.stringify(data));
                            });
                        } else {
                            //lpSpinner.Hide();
                            console.log('There was nothing to save back to the database.');
                            alert('There was nothing to save back to the database.');
                        }
                    },
                    remove: function (result) {
                        console.log('REMOVE: result: ' + JSON.stringify(result));
                        var paybackId = result.PaybackId;
                        //
                        // This is where we delete from PaybackItem table.
                        //
                        $.ajax({
                            url: operationUriPrefix + "odata/PaybackItems(" + paybackId + ")",
                            dataType: "json",
                            contentType: "application/json",
                            type: "Delete"
                        }).done(function (result2) {
                            try {
                                if (result2) {
                                    //lpSpinner.Hide();
                                    alert('Error deleting: ' + result2 + ', ' + JSON.stringify(result2));
                                } else {
                                    console.log('In CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.delete: Successfully deleted from DB. result: ' + result2); // NOTHING COMES BACK HERE, it is undefined.... not sure why this is happening.
                                    $("#jsGridOngoingCosts").dxDataGrid("instance").refresh();
                                    //$("#jsGridSpendForecastSummary").dxDataGrid("instance").refresh();
                                    //lpSpinner.Hide();
                                }
                            } catch (e) {
                                //lpSpinner.Hide();
                                console.log('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.delete: ' + e.message + ', ' + e.stack);
                            }
                        }).fail(function (data) {
                            //lpSpinner.Hide();
                            var msg;
                            if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                            } else {
                                msg = JSON.stringify(data);
                            }
                            //alert('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.delete: ' + msg); //+ error.message.value + ' ' + error.innererror.message);
                            console.log('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().paybackItems.delete: ' + JSON.stringify(data));
                            //var error = JSON.parse(data.responseText)["odata.error"];
                        });
                    }
                });

                //console.log("Url:   " + operationUriPrefix + "odata/PaybackTypes?$filter=PaybackFlag eq false&$orderby=Name asc");

                $.ajax({
                    url: operationUriPrefix + "odata/PaybackTypes?$filter=PaybackFlag eq false&$orderby=Name asc",
                    dataType: "json",
                    contentType: "application/json"
                }).done(function (result) {
                    var ongoingItemTypes = result.value;
                    console.log('In CarForm3.aspx.populateOngoingCostsNotReadOnly().ongoingItemTypes.load: ongoingItemTypes: ' + JSON.stringify(ongoingItemTypes));

                    $("#jsGridOngoingCosts").dxDataGrid({
                        dataSource: {
                            store: paybackItems
                        },
                        loadPanel: {
                            enabled: false
                        },
                        cacheEnabled: true,
                        editing: {
                            mode: "row",
                            allowUpdating: true,
                            allowDeleting: true,
                            allowAdding: true
                        },
                        paging: {
                            pageSize: 25
                        },
                        pager: {
                            showPageSizeSelector: true,
                            allowedPageSizes: [10, 25, 50, 100, 5000]
                        },
                        remoteOperations: false,
                        searchPanel: {
                            visible: false
                        },
                        allowColumnReordering: false,
                        allowColumnResizing: false,
                        rowAlternationEnabled: false,
                        showBorders: true,
                        filterRow: { visible: false },
                        columns: [
                            {
                                dataField: "PaybackTypeId",
                                caption: "Ongoing Cost Type",
                                width: '25%',
                                lookup: {
                                    dataSource: ongoingItemTypes,
                                    valueExpr: "PaybackTypeId",
                                    displayExpr: "Name",
                                },
                                validationRules: [{ type: "required" }]
                            },
                            {
                                dataField: "Amount",
                                caption: "Ongoing $ Per Year",
                                dataType: "number",
                                format: { type: "currency", precision: 0 },
                                width: '15%',
                                validationRules: [{ type: "required" }]
                            },
                            {
                                dataField: "Comments",
                                caption: "Comments",
                                dataType: "string",
                                width: '60%'
                            }
                        ],
                        summary: {
                            totalItems: [{
                                column: "PaybackTypeId",
                                alignment: "left",
                                displayFormat: "Total"
                            },
                            {
                                column: "Amount",
                                summaryType: "sum",
                                alignment: "right",
                                valueFormat: "currency",
                                displayFormat: "{0}"
                            }]
                        },
                        onKeyDown: function (e) {
                            if (e.event.keyCode == 13 || e.event.keyCode == 190 || e.event.keyCode == 110)
                            {
                                console.log("OngoingCost: Enter/Decimal/Period buttons disabled.");
                                e.event.preventDefault();
                                return false;
                            }
                        },
                        onEditorPreparing: function (e) {
                            //Added fix for backspace prevention (only when there is a value)
                            if (e.parentType == "dataRow") {
                                e.editorOptions.onKeyDown = function (arg) {
                                    var value = e.element.find("input").val();
                                    if (arg.event.keyCode == 8) {
                                        if (e.editorName === "dxSelectBox" || value.length < 1) {
                                            arg.event.preventDefault();
                                            arg.event.stopPropagation();
                                        }
                                    }
                                }
                            }
                        },
                        onCellPrepared: function (e) {
                            if (e.rowType == "totalFooter") {
                                e.cellElement.css({ "font-style": "italic", "font-weight": "bold" });
                            }
                        }
                    });
                }).fail(function (data) {
                    //lpSpinner.Hide();
                    var msg;
                    if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                        msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                    } else {
                        msg = JSON.stringify(data);
                    }
                    //alert('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().ongoingItemTypes.load: ' + msg);
                    console.log('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly().ongoingItemTypes.load: ' + JSON.stringify(data));
                });

            } catch (e) {
                console.log('Exception in CarForm3.aspx.populateOngoingCostsNotReadOnly(): ' + e.message + ', ' + e.stack);
            }
        };

        function populateOngoingCostsReadOnly() {
            try {
                console.log('In CarForm3.aspx.populateOngoingCostsReadOnly().');

                var paybackItems = new DevExpress.data.CustomStore({
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;
                        $.ajax({
                            url: operationUriPrefix + "odata/vPaybacks?$filter=CARId eq " + gCarId + " and PaybackFlag eq false",
                            dataType: "json",
                            contentType: "application/json"
                        }).done(function (result) {
                            deferred.resolve(result.value, {});
                        }).fail(function (data) {
                            //lpSpinner.Hide();
                            var msg;
                            if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                            } else {
                                msg = JSON.stringify(data);
                            }
                            //alert('Exception in CarForm3.aspx.populateOngoingCostsReadOnly().paybackItems.load: ' + msg);
                            console.log('Exception in CarForm3.aspx.populateOngoingCostsReadOnly().paybackItems.load: ' + JSON.stringify(data));
                        });
                        return deferred.promise();
                    }
                });


                $("#jsGridOngoingCosts").dxDataGrid({
                    dataSource: {
                        store: paybackItems
                    },
                    loadPanel: {
                        enabled: false
                    },
                    cacheEnabled: true,
                    editing: {
                        mode: "row",
                        allowUpdating: false,
                        allowDeleting: false,
                        allowAdding: false
                    },
                    paging: {
                        pageSize: 25
                    },
                    pager: {
                        showPageSizeSelector: true,
                        allowedPageSizes: [10, 25, 50, 100, 5000]
                    },
                    remoteOperations: false,
                    searchPanel: {
                        visible: false
                    },
                    allowColumnReordering: false,
                    allowColumnResizing: false,
                    rowAlternationEnabled: false,
                    showBorders: true,
                    filterRow: { visible: false },
                    columns: [
                        {
                            dataField: "Name",
                            caption: "Ongoing Cost Type",
                            dataType: "string",
                            width: '25%'
                        },
                        {
                            dataField: "Amount",
                            caption: "Ongoing $ Per Year",
                            dataType: "number",
                            format: { type: "currency", precision: 0 },
                            width: '15%'
                        },
                        {
                            dataField: "Comments",
                            caption: "Comments",
                            dataType: "string",
                            width: '60%'
                        }
                    ],
                    summary: {
                        totalItems: [{
                            column: "Name",
                            alignment: "left",
                            displayFormat: "Total"
                        },
                        {
                            column: "Amount",
                            summaryType: "sum",
                            alignment: "right",
                            valueFormat: "currency",
                            displayFormat: "{0}"
                        }]
                    },
                    onCellPrepared: function (e) {
                        if (e.rowType == "totalFooter") {
                            e.cellElement.css({ "font-style": "italic", "font-weight": "bold" });
                        }
                    }
                });

            } catch (e) {
                console.log('Exception in CarForm3.aspx.populateOngoingCostsReadOnly(): ' + e.message + ', ' + e.stack);
            }
        };

        function populateApproverComments() {
            try {
                $.ajax({
                    url: operationUriPrefix + "odata/vComments?$filter=CARId eq " + gCarId + " and RoleCategory eq 'Approver'",
                    dataType: "json",
                    success: function (result) {
                        try {
                            var comments = result.value;
                            console.log('comments.length: ' + comments.length);
                            var html = '';
                            for (var i = 0; i < comments.length; i++) {
                                html += '<table border=1>';
                                html += '  <tr>';
                                html += '    <td>User</td>'
                                html += '    <td>' + comments[i].UserName + '</td>';
                                html += '  </tr>';
                                html += '  <tr>';
                                html += '    <td>Date</td>'
                                html += '    <td>' + comments[i].Timestmp + '</td>';
                                html += '  </tr>';
                                html += '  <tr>';
                                html += '    <td>Collaboration Type</td>'
                                html += '    <td>Comments - ' + comments[i].RoleName + '</td>';
                                html += '  </tr>';
                                html += '  <tr>';
                                html += '    <td>Comments</td>'
                                html += '    <td>' + comments[i].Comments + '</td>';
                                html += '  </tr>';
                                html + '</table>';
                            }
                            // Populate the "COMMENTS" tab.
                            document.getElementById('approverComments').innerHTML = html;
                        } catch (e) {
                            console.log('Exception in CarForm3.aspx.populateApproverCommentsReadOnly():2: ' + e.message + ', ' + e.stack);
                        }
                    },
                    error: function (result) {
                        console.log('ERROR: GET vComments: ' + JSON.stringify(result));
                    },
                    timeout: 15000
                });
            } catch (e) {
                console.log('Exception in CarForm3.aspx.populateApproverCommentsReadOnly(): ' + e.message + ', ' + e.stack);
            }
        };

        function populateCollaboratorComments() {
            try {
                $.ajax({
                    url: operationUriPrefix + "odata/vComments?$filter=CARId eq " + gCarId + " and RoleCategory eq 'Collaborator'",
                    dataType: "json",
                    success: function (result) {
                        try {
                            var comments = result.value;
                            var html = '';
                            for (var i = 0; i < comments.length; i++) {
                                html += '<table border=1>';
                                html += '  <tr>';
                                html += '    <td>User</td>'
                                html += '    <td>' + comments[i].UserName + '</td>';
                                html += '  </tr>';
                                html += '  <tr>';
                                html += '    <td>Date</td>'
                                html += '    <td>' + comments[i].Timestmp + '</td>';
                                html += '  </tr>';
                                html += '  <tr>';
                                html += '    <td>Collaboration Type</td>'
                                html += '    <td>Comments - ' + comments[i].RoleName + '</td>';
                                html += '  </tr>';
                                html += '  <tr>';
                                html += '    <td>Comments</td>'
                                html += '    <td>' + comments[i].Comments + '</td>';
                                html += '  </tr>';
                                html + '</table>';
                            }
                            // Populate the "COMMENTS" tab.
                            document.getElementById('collaboratorComments').innerHTML = html;
                        } catch (e) {
                            console.log('Exception in CarForm3.aspx.populateCollaboratorComments():2: ' + e.message + ', ' + e.stack);
                        }
                    },
                    error: function (result) {
                        //deferred.reject("Data Loading Error");
                        console.log('ERROR: GET vComments: ' + JSON.stringify(result));
                    },
                    timeout: 15000
                });
            } catch (e) {
                console.log('Exception in CarForm3.aspx.populateCollaboratorComments(): ' + e.message + ', ' + e.stack);
            }
        };

        function populateWorkflow() {
            try {
                console.log('In CarForm3.aspx.populateWorkflow().');

                var assignmentList = new DevExpress.data.CustomStore({
                    load: function (loadOptions) {
                        var deferred = $.Deferred(),
                            args = {};
                        if (loadOptions.sort) {
                            args.orderby = loadOptions.sort[0].selector;
                            if (loadOptions.sort[0].desc)
                                args.orderby += " desc";
                        }
                        args.skip = loadOptions.skip;
                        args.take = loadOptions.take;
                        $.ajax({
                            url: operationUriPrefix + "odata/vAssignments?$filter=CARId eq " + gCarId,
                            dataType: "json",
                            contentType: "application/json"
                        }).done(function (result) {
                            deferred.resolve(result.value, {});
                        }).fail(function (data) {
                            //lpSpinner.Hide();
                            var msg;
                            if (JSON.stringify(data).indexOf('The specified URL cannot be found.') > -1) {
                                msg = 'There has been an error contacting the server. A firewall or network appliance may be interrupting this traffic.';
                            } else {
                                msg = JSON.stringify(data);
                            }
                            //alert('Exception in CarForm3.aspx.populateWorkflow().assignmentList.load: ' + msg);
                            console.log('Exception in CarForm3.aspx.populateWorkflow().assignmentList.load: ' + JSON.stringify(data));
                        });
                        return deferred.promise();
                    }
                });


                $("#jsGridAssignmentList").dxDataGrid({
                    dataSource: {
                        store: assignmentList
                    },
                    loadPanel: {
                        enabled: false
                    },
                    cacheEnabled: true,
                    editing: {
                        mode: "row",
                        allowUpdating: false,
                        allowDeleting: false,
                        allowAdding: false
                    },
                    paging: {
                        pageSize: 25
                    },
                    pager: {
                        showPageSizeSelector: true,
                        allowedPageSizes: [10, 25, 50, 100, 5000]
                    },
                    remoteOperations: false,
                    searchPanel: {
                        visible: false
                    },
                    allowColumnReordering: false,
                    allowColumnResizing: false,
                    rowAlternationEnabled: false,
                    showBorders: true,
                    filterRow: { visible: false },
                    columns: [
                        {
                            dataField: "AssignDate",
                            caption: "Assigned Date",
                            dataType: "date",
                            format: 'MM/dd/yyyy',
                            width: 75
                        },
                        {
                            dataField: "CurStatus",
                            caption: "Status",
                            dataType: "string",
                            width: 75
                        },
                        {
                            dataField: "UserName",
                            caption: "Assigned To",
                            dataType: "string",
                            width: 100
                        },
                        {
                            dataField: "Title",
                            caption: "Action",
                            dataType: "string",
                            width: 100
                        },
                        {
                            dataField: "RoleName",
                            caption: "Role",
                            dataType: "string",
                            width: 175
                        },
                        {
                            dataField: "CompletionDate",
                            caption: "Completed Date",
                            dataType: "date",
                            format: 'MM/dd/yyyy',
                            width: 75
                        }
                    ]
                });
            }
            catch (e) {
                console.log('Exception in CarForm3.aspx.populateWorkflow(): ' + e.message + ', ' + e.stack);
            }
        };

    </script>


    <!-- THESE CSS files are here because we are optimizing the loading speed of the page. -->
    <link type="text/css" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jsgrid/1.5.3/jsgrid.min.css" />
    <link type="text/css" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/jsgrid/1.5.3/jsgrid-theme.min.css" />
    <link href="/Content/Styles/google-material_plus_icons-icon.css" rel="stylesheet" type="text/css" />
    <link href="https://unpkg.com/gijgo@1.9.13/css/gijgo.css" rel="stylesheet" type="text/css" />

    <p id="CARForm-Title" style="color: red;"></p>

    <div id="tabs" style="border: none;">
        <ul class="nav nav-tabs">
            <li><a class="tabCustom tabCustomBold" href="#tabs-1-BASICINFO">BASIC INFO</a></li>
            <li><a class="tabCustom tabCustomBold" href="#tabs-2-DESCRIPTION">DESCRIPTION</a></li>
            <li><a class="tabCustom tabCustomBold" href="#tabs-3-COSTSHEET">COST SHEET</a></li>
            <li><a class="tabCustom tabCustomBold" href="#tabs-4-SPENDFORECAST">SPEND FORECAST</a></li>
            <li><a class="tabCustom tabCustomBold" href="#tabs-5-PAYBACK">PAYBACK</a></li>
            <li><a class="tabCustom tabCustomBold" href="#tabs-6-COMMENTS">COMMENTS</a></li>
            <li><a class="tabCustom tabCustomBold" href="#tabs-7-ATTACHMENTS">ATTACHMENTS</a></li>
            <li><a class="tabCustom tabCustomBold" href="#tabs-8-WORKFLOW">WORKFLOW</a></li>
            <li style="display: none;"><a class="tabCustom tabCustomBold" href="#tabs-9-RACI">RACI</a></li>
        </ul>

        <div id="divProject" class="customProject">
            <label id="lblProject"></label>
        </div>


        <hr>

        <div id="tabs-1-BASICINFO">
            <div id="alertNotCompleted" class="row" style="display: none;">
                <div class="col-xs-3"></div>
                <div class="col-xs-6">
                    <div class="alert alert-danger" role="alert">
                        <h4 class="alert-heading">Required Fields Incomplete!</h4>
                        <p>All required fields must be entered before completing the other tabs.</p>
                    </div>
                </div>
                <div class="col-xs-3"></div>
            </div>
            <div id="alertCompleted" class="row" style="display: none;">
                <div class="col-xs-3"></div>
                <div class="col-xs-6">
                    <div class="alert alert-success" role="alert">
                        <h4 class="alert-heading">Required Fields Complete!</h4>
                        <p>The required fields were entered, click <b>SAVE</b> to complete the other tabs.</p>
                    </div>
                </div>
                <div class="col-xs-3"></div>
            </div>
            <div class="row">
                <div class="col-xs-6">
                    <div class="row">
                        <div class="col-xs-12">
                            <span class="custom-header randy">HEADING</span>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-xs-12">
                            <hr>
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="ProjectTitle" class="required-field customLabel">Project Title</label>
                        </div>
                        <div id="divProjectTitle" class="col-xs-6">
                            <input class="form-control requiredClass" id="ProjectTitle" />
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label class="customLabel" for="ProjectNumber">Project #</label>
                        </div>
                        <div id="divProjectNumber" class="col-xs-6">
                            <input type="text" class="form-control requiredClass" id="ProjectNumber" />
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="location" class="required-field customLabel">Location</label>
                        </div>
                        <div id="divLocation" class="col-xs-6">
                            <dx:ASPxDropDownEdit
                                ID="ASPxDropDownEdit1"
                                runat="server"
                                ClientInstanceName="ddeLocation"
                                AllowUserInput="false"
                                AnimationType="None"
                                Width="100%"
                                ClientSideEvents-KeyUp="SelectTreeviewLocation"
                                ItemStyle-SelectedStyle-BackColor="#0083A9"
                                ButtonStyle-HoverStyle-BackColor="#0083A9"
                                ButtonStyle-PressedStyle-BackColor="#0083A9">
                                <ClientSideEvents Init="LocInit" DropDown="LocOnDropDown" />
                                <DropDownWindowTemplate>
                                    <div>
                                        <dx:ASPxTreeList
                                            ID="treeLocation"
                                            ClientInstanceName="treeLocation"
                                            runat="server" OnCustomJSProperties="treeLocation_CustomJSProperties"
                                            Width="500px" DataSourceID="dsLoc" KeyFieldName="RowKey" ParentFieldName="ParentKey" SettingsDataSecurity-AllowReadUnlistedFieldsFromClientApi="True">
                                            <Settings VerticalScrollBarMode="Visible" />
                                            <SettingsBehavior ExpandCollapseAction="NodeDblClick" AutoExpandAllNodes="true" />
                                            <ClientSideEvents FocusedNodeChanged="LocNodeSelect" />
                                            <Columns>
                                                <dx:TreeListDataColumn FieldName="Name" Name="Name" Caption="Name" />
                                            </Columns>
                                            <SettingsBehavior FocusNodeOnExpandButtonClick="false" ExpandCollapseAction="Button" AllowFocusedNode="true" FocusNodeOnLoad="false" />
                                        </dx:ASPxTreeList>
                                    </div>
                                    <table style="background-color: White; width: 100%;">

                                        <tr>
                                            <td style="padding: 10px;">
                                                <dx:ASPxButton
                                                    ID="btnLocClear"
                                                    ClientEnabled="false"
                                                    ClientInstanceName="btnLocClear"
                                                    runat="server"
                                                    AutoPostBack="false"
                                                    Text="Clear" BackColor="#0083A9">
                                                    <ClientSideEvents Click="LocClearSelection" />
                                                </dx:ASPxButton>
                                            </td>
                                            <td style="text-align: right; padding: 10px;">
                                                <dx:ASPxButton
                                                    ID="btnLocSelect"
                                                    ClientEnabled="false"
                                                    ClientInstanceName="btnLocSelect"
                                                    runat="server"
                                                    AutoPostBack="false"
                                                    Text="Select" BackColor="#0083A9">
                                                    <ClientSideEvents Click="LocUpdateSelection" />
                                                </dx:ASPxButton>

                                                <dx:ASPxButton ID="btnLocClose" runat="server" AutoPostBack="false" Text="Close" BackColor="#0083A9">
                                                    <ClientSideEvents Click="function(s,e) { ddeLocation.HideDropDown(); }" />
                                                </dx:ASPxButton>
                                            </td>
                                        </tr>
                                    </table>
                                </DropDownWindowTemplate>
                                <ValidationSettings ValidationGroup="vgCAR" Display="Dynamic" SetFocusOnError="true" CausesValidation="true" ErrorDisplayMode="ImageWithTooltip">
                                    <RequiredField IsRequired="true" ErrorText="Location is required" />
                                </ValidationSettings>
                            </dx:ASPxDropDownEdit>
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="ProjManagerId" class="required-field customLabel">Project Manager</label>
                        </div>
                        <div id="divprojectManager" class="col-xs-6">
                            <select name="ProjManagerId" class="form-control" onchange="AreRequiredFieldsCompleted();" id="ProjManagerId"></select>
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="CostCenterNumber" class="required-field customLabel">Cost Center #</label>
                        </div>
                        <div id="divCostCenterNumber" class="col-xs-3">
                            <input type="text" class="form-control" onchange="AreRequiredFieldsCompleted();" id="CostCenterNumber" />
                        </div>
                        <div class="col-xs-5"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="CostCenterDesc" class="customLabel">Cost Center Description</label>
                        </div>
                        <div id="divCostCenterDesc" class="col-xs-6">
                            <input class="form-control" id="CostCenterDesc" />
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="CurrencyTypeId" class="required-field customLabel">Currency Type</label>
                        </div>
                        <div id="divcurrencyType" class="col-xs-6">
                            <select name="CurrencyTypeId" class="form-control" onchange="AreRequiredFieldsCompleted();" id="CurrencyTypeId"></select>
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="ExchangeRate" class="customLabel">Exchange Rate</label>
                        </div>
                        <div id="divExchangeRate" class="col-xs-3">
                            <input type="text" class="form-control OnlyDecimal" id="ExchangeRate" />
                        </div>
                        <div class="col-xs-5"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="AuditRequiredFlag" class="customLabel">Audit</label>
                        </div>
                        <div id="divAuditRequired" class="col-xs-8">
                            <label for="AuditRequired_Yes" class="radio-inline customRadio">
                                <input id="AuditRequired_Yes" type="radio" name="AuditRequiredFlag" value="Yes" onchange="AuditRequired_OnChange();">Yes</label>
                            <label for="AuditRequired_No" class="radio-inline customRadio">
                                <input id="AuditRequired_No" type="radio" name="AuditRequiredFlag" value="No" onchange="AuditRequired_OnChange();">No</label>
                        </div>
                    </div>
                    <div class="row customRow toggleAuditRequired" id="rowAuditDate">
                        <div class="col-xs-4">
                            <label for="AuditDate" class="required-field customLabel">Audit Date</label>
                        </div>
                        <div id="divAuditDate" class="col-xs-3">
                            <input type="text" class="form-control" id="AuditDate" />
                        </div>
                        <div class="col-xs-5"></div>
                    </div>
                </div>
                <div class="col-xs-6">
                    <div class="row">
                        <div class="col-xs-12">
                            <span class="custom-header">CAR DETAILS</span>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-xs-12">
                            <hr>
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="ProjectTypeId" class="required-field customLabel">Project Type</label>
                        </div>
                        <div id="divprojectType" class="col-xs-6">
                            <select name="ProjectTypeId" id="ProjectTypeId" onchange="AreRequiredFieldsCompleted();"></select>
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="CombPlantFlag" class="customLabel">Is Combined Plant?</label>
                        </div>
                        <div id="divCombPlantFlag" class="col-xs-8">
                            <label for="CombPlantFlag_Yes" class="radio-inline customRadio">
                                <input id="CombPlantFlag_Yes" type="radio" name="CombPlantFlag" value="Yes">Yes</label>
                            <label for="CombPlantFlag_No" class="radio-inline customRadio">
                                <input id="CombPlantFlag_No" type="radio" name="CombPlantFlag" value="No">No</label>
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="ProjSponsorId" class="customLabel">Project Sponsor</label>
                        </div>
                        <div id="divprojectSponsor" class="col-xs-6">
                            <select name="ProjSponsorId" id="ProjSponsorId" onchange="AreRequiredFieldsCompleted();"></select>
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="pillar" class="required-field customLabel">Pillar Type</label>
                        </div>
                        <div id="divPillar" class="col-xs-6">
                            <dx:ASPxDropDownEdit
                                ID="treePillar"
                                runat="server"
                                ClientInstanceName="ddePillar"
                                AllowUserInput="false"
                                AnimationType="None"
                                Width="100%"
                                ClientSideEvents-KeyUp="SelectTreeviewPillar"
                                ItemStyle-SelectedStyle-BackColor="#0083A9"
                                ButtonStyle-HoverStyle-BackColor="#0083A9"
                                ButtonStyle-PressedStyle-BackColor="#0083A9">
                                <ClientSideEvents Init="PillarInit" DropDown="PillarOnDropDown" />
                                <DropDownWindowTemplate>
                                    <div>
                                        <dx:ASPxTreeList
                                            ID="treePillar"
                                            ClientInstanceName="treePillar"
                                            runat="server" OnCustomJSProperties="treePillar_CustomJSProperties"
                                            Width="500px" DataSourceID="dsPillar" KeyFieldName="PillarId" ParentFieldName="ParentPillarId" SettingsDataSecurity-AllowReadUnlistedFieldsFromClientApi="True">
                                            <Settings VerticalScrollBarMode="Visible" />
                                            <SettingsBehavior ExpandCollapseAction="NodeDblClick" AutoExpandAllNodes="true" />
                                            <ClientSideEvents FocusedNodeChanged="PillarNodeSelect" />
                                            <Columns>
                                                <dx:TreeListDataColumn FieldName="Name" Name="Name" Caption="Name" />
                                            </Columns>
                                            <SettingsBehavior FocusNodeOnExpandButtonClick="false" ExpandCollapseAction="Button" AllowFocusedNode="true" FocusNodeOnLoad="false" />
                                        </dx:ASPxTreeList>
                                    </div>
                                    <table style="background-color: White; width: 100%;">
                                        <tr>
                                            <td style="padding: 10px;">
                                                <dx:ASPxButton
                                                    ID="btnPillarClear"
                                                    ClientEnabled="false"
                                                    ClientInstanceName="btnPillarClear"
                                                    runat="server"
                                                    AutoPostBack="false"
                                                    Text="Clear"
                                                    BackColor="#0083A9">
                                                    <ClientSideEvents Click="PillarClearSelection" />
                                                </dx:ASPxButton>
                                            </td>
                                            <td style="text-align: right; padding: 10px;">
                                                <dx:ASPxButton
                                                    ID="btnPillarSelect"
                                                    ClientEnabled="false"
                                                    ClientInstanceName="btnPillarSelect"
                                                    runat="server"
                                                    AutoPostBack="false"
                                                    Text="Select" BackColor="#0083A9">
                                                    <ClientSideEvents Click="PillarUpdateSelection" />
                                                </dx:ASPxButton>

                                                <dx:ASPxButton ID="btnPillarClose" runat="server" AutoPostBack="false" Text="Close" BackColor="#0083A9">
                                                    <ClientSideEvents Click="function(s,e) { ddePillar.HideDropDown(); }" />
                                                </dx:ASPxButton>
                                            </td>
                                        </tr>
                                    </table>
                                </DropDownWindowTemplate>
                                <ValidationSettings ValidationGroup="vgCAR" Display="Dynamic" SetFocusOnError="true" CausesValidation="true" ErrorDisplayMode="ImageWithTooltip">
                                    <RequiredField IsRequired="true" ErrorText="Pillar Type is required" />
                                </ValidationSettings>
                            </dx:ASPxDropDownEdit>
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="StartDate" class="required-field customLabel">Project Start Date</label>

                        </div>
                        <div id="divStartDate" class="col-xs-3">
                            <input type="text" class="form-control" id="StartDate" onchange="DateChanged();" />
                        </div>
                        <div class="col-xs-5"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="EndDate" class="required-field customLabel">Completion Date</label>
                        </div>
                        <div id="divEndDate" class="col-xs-3">
                            <input type="text" class="form-control" id="EndDate" onchange="DateChanged();" />
                        </div>
                        <div class="col-xs-5"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="numberOfDays" class="customLabel"># of Days</label>
                        </div>
                        <div id="divnumberOfDays" class="col-xs-3">
                            <input type="text" class="form-control" id="numberOfDays" readonly />
                        </div>
                        <div class="col-xs-5"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="FiscalYear" class="customLabel">Fiscal Year</label>
                        </div>
                        <div id="divFiscalYear" class="col-xs-3">
                            <input type="text" class="form-control" id="FiscalYear" />
                        </div>
                        <div
                            class="col-xs-5">
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="BookDeprLife" class="customLabel">Depreciation Life</label>
                        </div>
                        <div id="divBookDeprLife" class="col-xs-2">
                            <select name="BookDeprLife" id="BookDeprLife"></select>
                        </div>
                        <div class="col-xs-6"></div>
                    </div>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <br>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <hr>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <br>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-6">
                    <div class="row">
                        <div class="col-xs-12">
                            <span class="custom-header">CAPITAL PLAN STATEMENTS</span>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-xs-12">
                            <hr>
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="InCapitalPlanFlag" class="required-field customLabel">In Capital Plan?</label>
                        </div>
                        <div id="divInCapPlanFlag" class="col-xs-8">
                            <label for="InCapPlanFlag_Yes" class="radio-inline customRadio">
                                <input id="InCapPlanFlag_Yes" type="radio" name="InCapitalPlanFlag" value="Yes" onchange="InCapPlanChanged();">Yes</label>
                            <label for="InCapPlanFlag_No" class="radio-inline customRadio">
                                <input id="InCapPlanFlag_No" type="radio" name="InCapitalPlanFlag" value="No" onchange="InCapPlanChanged();">No</label>
                        </div>
                    </div>
                    <div class="row customRow toggleInCapPlan" id="rowExpenseOnly">
                        <div class="col-xs-4">
                            <label for="ExpenseOnlyFlag" class="customLabel">Is it Expense Only?</label>
                        </div>
                        <div id="divExpenseOnlyFlag" class="col-xs-8">
                            <label for="ExpenseOnlyFlag_Yes" class="radio-inline customRadio">
                                <input id="ExpenseOnlyFlag_Yes" type="radio" value="Yes" name="ExpenseOnlyFlag">Yes</label>
                            <label for="ExpenseOnlyFlag_No" class="radio-inline customRadio">
                                <input id="ExpenseOnlyFlag_No" type="radio" value="No" name="ExpenseOnlyFlag">No</label>
                        </div>
                    </div>
                    <div class="row customRow" id="rowIncrementalToCapitalPlan">
                        <div class="col-xs-4">
                            <label for="IncCapPlanFlag" class="customLabel">Incremental to Capital Plan?</label>
                        </div>
                        <div id="divIncCapPlanFlag" class="col-xs-8">
                            <label for="IncCapPlanFlag_Yes" class="radio-inline customRadio">
                                <input id="IncCapPlanFlag_Yes" type="radio" value="Yes" name="IncCapPlanFlag">Yes</label>
                            <label for="IncCapPlanFlag_No" class="radio-inline customRadio">
                                <input id="IncCapPlanFlag_No" type="radio" value="No" name="IncCapPlanFlag">No</label>
                        </div>
                    </div>
                    <div class="row customRow" id="rowCapitalPlanItem">
                        <div class="col-xs-4">
                            <label for="CapitalPlanItemId" class="customLabel">Capital Plan Item</label>
                        </div>
                        <div id="divCapitalPlanItem" class="col-xs-6">
                            <select name="CapitalPlanItemId" id="CapitalPlanItemId"></select>
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="SubstitutionFlag" class="required-field customLabel">Substitution?</label>
                        </div>
                        <div id="divSubstitutionFlag" class="col-xs-8">
                            <label for="SubstitutionFlag_Yes" class="radio-inline customRadio">
                                <input id="SubstitutionFlag_Yes" type="radio" name="SubstitutionFlag" value="Yes" onchange="SubstitutionFlag_OnChange();">Yes</label>
                            <label for="SubstitutionFlag_No" class="radio-inline customRadio">
                                <input id="SubstitutionFlag_No" type="radio" name="SubstitutionFlag" value="No" onchange="SubstitutionFlag_OnChange();">No</label>
                        </div>
                    </div>
                    <div class="row customRow toggleSubstitution" id="rowSubstitutionProject">
                        <div class="col-xs-4">
                            <label for="SubstitutionProject" class="customLabel">Substitution Project?</label>
                        </div>
                        <div id="divSubstitutionProject" class="col-xs-6">
                            <input class="form-control" id="SubstitutionProject" />
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="AssetsAffectedFlag" class="required-field customLabel">Assets affected (transferring, retiring, etc.) as part of this project?</label>
                        </div>
                        <div id="divAssetsAffectedFlag" class="col-xs-8">

                            <label for="AssetsAffectedFlag_Yes" class="radio-inline customRadio">
                                <input id="AssetsAffectedFlag_Yes" type="radio" name="AssetsAffectedFlag" value="Yes" onchange="AssetsAffectedFlag_OnChange();">Yes</label>
                            <label for="AssetsAffectedFlag_No" class="radio-inline customRadio">
                                <input id="AssetsAffectedFlag_No" type="radio" name="AssetsAffectedFlag" value="No" onchange="AssetsAffectedFlag_OnChange();">No</label>
                        </div>
                    </div>
                    <div class="row customRow toggleAssetsAffected" id="rowAssetWriteOffs">
                        <div class="col-xs-4">
                            <label for="AssetWriteOffs" class="customLabel">Asset Write-Offs (Note: CTID Attachment Required)</label>
                        </div>
                        <div id="divAssetWriteOffs" class="col-xs-6">
                            <input type="text" class="form-control OnlyDecimal" id="AssetWriteOffs" />
                        </div>
                        <div class="col-xs-2"></div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="CompBidsFlag" class="required-field customLabel">Were competitive bids received for this project?</label>
                        </div>
                        <div id="divCompBidsFlag" class="col-xs-8">
                            <label for="CompBidsFlag_Yes" class="radio-inline customRadio">
                                <input id="CompBidsFlag_Yes" type="radio" onchange="AreRequiredFieldsCompleted();" value="Yes" name="CompBidsFlag">Yes</label>
                            <label for="CompBidsFlag_No" class="radio-inline customRadio">
                                <input id="CompBidsFlag_No" type="radio" onchange="AreRequiredFieldsCompleted();" value="No" name="CompBidsFlag">No</label>
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="VendorContractFlag" class="required-field customLabel">Is there a vendor contract(s)?</label>
                        </div>
                        <div id="divVendorContractFlag" class="col-xs-8">

                            <label for="VendorContractFlag_Yes" class="radio-inline customRadio">
                                <input id="VendorContractFlag_Yes" onchange="AreRequiredFieldsCompleted();" type="radio" value="Yes" name="VendorContractFlag">Yes</label>
                            <label for="VendorContractFlag_No" class="radio-inline customRadio">
                                <input id="VendorContractFlag_No" onchange="AreRequiredFieldsCompleted();" type="radio" value="No" name="VendorContractFlag">No</label>
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="ExcessCapacityFlag" class="required-field customLabel">Does excess capacity exist elsewhere within Smithfield?</label>
                        </div>
                        <div id="divExcessCapacityFlag" class="col-xs-8">
                            <label for="ExcessCapacityFlag_Yes" class="radio-inline customRadio">
                                <input id="ExcessCapacityFlag_Yes" onchange="AreRequiredFieldsCompleted();" class="requiredClass" type="radio" value="Yes" name="ExcessCapacityFlag">Yes</label>
                            <label for="ExcessCapacityFlag_No" class="radio-inline customRadio">
                                <input id="ExcessCapacityFlag_No" onchange="AreRequiredFieldsCompleted();" type="radio" value="No" name="ExcessCapacityFlag">No</label>
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="NewTechFlag" class="customLabel">Is this an expenditure for new technology?</label>
                        </div>
                        <div id="divNewTechFlag" class="col-xs-8">
                            <label for="NewTechFlag_Yes" class="radio-inline customRadio">
                                <input id="NewTechFlag_Yes" type="radio" value="Yes" name="NewTechFlag">Yes</label>
                            <label for="NewTechFlag_No" class="radio-inline customRadio">
                                <input id="NewTechFlag_No" type="radio" value="No" name="NewTechFlag">No</label>
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="SpecMaintFlag" class="required-field customLabel">Will special maintenance skills need to be added?</label>
                        </div>
                        <div id="divSpecMaintFlag" class="col-xs-8">
                            <label for="SpecMaintFlag_Yes" class="radio-inline customRadio">
                                <input id="SpecMaintFlag_Yes" onchange="AreRequiredFieldsCompleted();" type="radio" value="Yes" name="SpecMaintFlag">Yes</label>
                            <label for="SpecMaintFlag_No" class="radio-inline customRadio">
                                <input id="SpecMaintFlag_No" onchange="AreRequiredFieldsCompleted();" type="radio" value="No" name="SpecMaintFlag">No</label>
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="ExcessMaintFlag" class="required-field customLabel">Will excess operating or maintenance expense be added?</label>
                        </div>
                        <div id="divExcessMaintFlag" class="col-xs-8">
                            <label for="ExcessMaintFlag_Yes" class="radio-inline customRadio">
                                <input id="ExcessMaintFlag_Yes" onchange="AreRequiredFieldsCompleted();" type="radio" value="Yes" name="ExcessMaintFlag">Yes</label>
                            <label for="ExcessMaintFlag_No" class="radio-inline customRadio">
                                <input id="ExcessMaintFlag_No" onchange="AreRequiredFieldsCompleted();" type="radio" value="No" name="ExcessMaintFlag">No</label>
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="SimplePaybackFlag" class="required-field customLabel">Is this a Simple Payback?</label>
                        </div>
                        <div id="divSimplePaybackFlag" class="col-xs-8">
                            <label for="SimplePaybackFlag_Yes" class="radio-inline customRadio">
                                <input id="SimplePaybackFlag_Yes" onchange="AreRequiredFieldsCompleted();" type="radio" value="Yes" name="SimplePaybackFlag">Yes</label>
                            <label for="SimplePaybackFlag_No" class="radio-inline customRadio">
                                <input id="SimplePaybackFlag_No" onchange="AreRequiredFieldsCompleted();" type="radio" value="No" name="SimplePaybackFlag">No</label>
                        </div>
                    </div>
                </div>
                <div class="col-xs-6">
                    <div class="row">
                        <div class="col-xs-12">
                            <span class="custom-header">LEASE DATA</span>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-xs-12">
                            <hr>
                        </div>
                    </div>
                    <div class="row customRow">
                        <div class="col-xs-4">
                            <label for="LeaseReqFlag" class="required-field customLabel">Is a lease required?</label>
                        </div>
                        <div id="divLeaseReqFlag" class="col-xs-8">
                            <label for="LeaseReqFlag_Yes" class="radio-inline customRadio">
                                <input id="LeaseReqFlag_Yes" type="radio" onchange="LeaseReq_Changed();" name="LeaseReqFlag" value="Yes">Yes</label>
                            <label for="LeaseReqFlag_No" class="radio-inline customRadio">
                                <input id="LeaseReqFlag_No" type="radio" onchange="LeaseReq_Changed();" name="LeaseReqFlag" value="No">No</label>
                        </div>
                    </div>
                    <div class="row customRow toggleLeaseReq" id="rowLeaseOwnFlag">
                        <div class="col-xs-4">
                            <label for="LeaseOwnFlag" class="required-field customLabel">Will Smithfield own the item(s) at the end of the lease term?</label>
                        </div>
                        <div id="divLeaseOwnFlag" class="col-xs-8">
                            <label for="LeaseOwnFlag_Yes" class="radio-inline customRadio">
                                <input id="LeaseOwnFlag_Yes" onchange="LeaseTypeChanged();" type="radio" name="LeaseOwnFlag" value="Yes">Yes</label>
                            <label for="LeaseOwnFlag_No" class="radio-inline customRadio">
                                <input id="LeaseOwnFlag_No" onchange="LeaseTypeChanged();" type="radio" name="LeaseOwnFlag" value="No">No</label>
                        </div>
                    </div>
                    <div class="row customRow toggleLeaseReq" id="rowLeaseBargainOptionFlag">
                        <div class="col-xs-4">
                            <label for="LeaseBargainOptionFlag" class="required-field customLabel">Does the lease contain a bargain purchase option?</label>
                        </div>
                        <div id="divLeaseBargainOptionFlag" class="col-xs-8">
                            <label for="LeaseBargainOptionFlag_Yes" class="radio-inline customRadio">
                                <input id="LeaseBargainOptionFlag_Yes" onchange="LeaseTypeChanged();" type="radio" value="Yes" name="LeaseBargainOptionFlag">Yes</label>
                            <label for="LeaseBargainOptionFlag_No" class="radio-inline customRadio">
                                <input id="LeaseBargainOptionFlag_No" onchange="LeaseTypeChanged();" type="radio" value="No" name="LeaseBargainOptionFlag">No</label>
                        </div>
                    </div>
                    <div class="row customRow toggleLeaseReq" id="rowUsefulLifeYears">
                        <div class="col-xs-4">
                            <label for="UsefulLifeYears" class="customLabel">Economic Useful Life of the item (years)</label>
                        </div>
                        <div id="divUsefulLifeYears" class="col-xs-3">
                            <select name="UsefulLifeYears" id="UsefulLifeYears"></select>
                        </div>
                        <div class="col-xs-5"></div>
                    </div>
                    <div class="row customRow toggleLeaseReq" id="rowLeaseTermYears">
                        <div class="col-xs-4">
                            <label for="LeaseTermYears" class="customLabel">Lease Term (years)</label>
                        </div>
                        <div id="divLeaseTermYears" class="col-xs-3">
                            <input type="text" class="form-control OnlyDecimal" id="LeaseTermYears" onchange="LeaseRatio_OnChange();" />
                        </div>
                        <div class="col-xs-5"></div>
                    </div>
                    <div class="row customRow toggleLeaseReq" id="rowLeaseRatio">
                        <div class="col-xs-4">
                            <label for="LeaseRatio" class="customLabel">Lease to Economic Life Ratio</label>
                        </div>
                        <div id="divLeaseRatio" class="col-xs-3">
                            <input type="text" class="form-control" id="LeaseRatio" readonly />
                        </div>
                        <div class="col-xs-5"></div>
                    </div>
                    <div class="row customRow toggleLeaseReq" id="rowLeaseNPVFlag">
                        <div class="col-xs-4">
                            <label for="LeaseNPVFlag" class="required-field customLabel">Is NPV of the lease payments >= 90% of the FMV?</label>
                        </div>
                        <div id="divLeaseNPVFlag" class="col-xs-8">
                            <label for="LeaseNPVFlag_Yes" class="radio-inline customRadio">
                                <input id="LeaseNPVFlag_Yes" onchange="LeaseTypeChanged();" type="radio" value="Yes" name="LeaseNPVFlag">Yes</label>
                            <label for="LeaseNPVFlag_No" class="radio-inline customRadio">
                                <input id="LeaseNPVFlag_No" onchange="LeaseTypeChanged();" type="radio" value="No" name="LeaseNPVFlag">No</label>
                        </div>
                    </div>
                    <div class="row customRow toggleLeaseReq" id="rowLeaseType">
                        <div class="col-xs-4">
                            <label for="LeaseType" class="customLabel">Lease Type</label>
                        </div>
                        <div id="divLeaseType" class="col-xs-4">
                            <input type="text" class="form-control" id="LeaseType" readonly />
                        </div>
                        <div class="col-xs-4"></div>
                    </div>
                </div>
            </div>
        </div>
        <div id="tabs-2-DESCRIPTION">
            <div class="row">
                <div class="col-xs-12">
                    <span class="custom-header">DESCRIPTION</span>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <hr>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-12">
                    <label for="ProjectDesc" class="required-field customLabel">What is the proposed project?</label>
                </div>
            </div>
            <div class="row customRow">
                <div id="divProjectDesc" class="col-xs-12">
                    <div id="ProjectDesc"></div>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <br>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-12">
                    <label for="ProjectReason" class="required-field customLabel">Why do you want to do this project?</label>
                </div>
            </div>
            <div class="row customRow">
                <div id="divProjectReason" class="col-xs-12">
                    <div id="ProjectReason"></div>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <br>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-12">
                    <label for="ProjectJustification" class="required-field customLabel">Project Justification?</label>
                </div>
            </div>
            <div class="row customRow">
                <div id="divProjectJustification" class="col-xs-12">
                    <div id="ProjectJustification"></div>
                </div>
            </div>
        </div>
        <div id="tabs-3-COSTSHEET">
            <div class="row">
                <div class="col-xs-12">
                    <span class="custom-header">COST SHEET</span>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <hr>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <div id="jsGridCostSheet"></div>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <br>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-12">
                    <span class="custom-header">FIXED (PERCENTAGE-BASED) COST</span>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <hr>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <div id="jsGridFixedCost"></div>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <div id="jsGridSummaryCost"></div>
                </div>
            </div>
        </div>
        <div id="tabs-4-SPENDFORECAST">

            <div class="row">
                <div class="col-xs-12">
                    <span class="custom-header">FORECAST PARAMETERS</span>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <hr>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-2">
                    <label class="customLabel" for="projectedCapitalSpending">Projected Capital Spending</label>
                </div>
                <div id="divprojectedCapitalSpending" class="col-xs-2">
                    <input type="text" class="form-control" id="projectedCapitalSpending" readonly />
                </div>
                <div class="col-xs-8"></div>
            </div>
            <div class="row customRow">
                <div class="col-xs-2">
                    <label class="customLabel" for="amountForecast">Amount Forecast</label>
                </div>
                <div id="divamountForecast" class="col-xs-2">
                    <input type="text" class="form-control" id="amountForecast" readonly />
                </div>
                <div class="col-xs-8"></div>
            </div>
            <div class="row customRow">
                <div class="col-xs-2">
                    <label class="customLabel" for="amountLeftToForecast">Amount left to forecast</label>
                </div>
                <div id="divamountLeftToForecast" class="col-xs-2">
                    <input type="text" class="form-control" id="amountLeftToForecast" readonly />
                </div>
                <div class="col-xs-8"></div>
            </div>
            <div class="row customRow">
                <div class="col-xs-12">
                    <br>
                </div>
            </div>
            <div id="alertSpendForecastIsEmpty" class="row">
                <div class="col-xs-3"></div>
                <div class="col-xs-6">
                    <div class="alert alert-warning" role="alert">
                        <h4 class="alert-heading"><span style="text-align: center">Please click <b>Edit</b> to add a new spend forecast.</span></h4>
                    </div>
                </div>
                <div class="col-xs-3"></div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <div id="jsGridSpendForecast"></div>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <div id="jsGridSpendForecastSummary"></div>
                </div>
            </div>
        </div>
        <div id="tabs-5-PAYBACK">
            <div class="row">
                <div class="col-xs-12">
                    <span class="custom-header">PAYBACK PARAMETERS</span>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <hr>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-2">
                    <label class="customLabel" for="NPV">NPV Summary (if applicable)</label>
                </div>
                <div id="divNPV" class="col-xs-2">
                    <input type="text" class="form-control OnlyDecimal" id="NPV" />
                </div>
                <div class="col-xs-8"></div>
            </div>
            <div class="row customRow">
                <div class="col-xs-2">
                    <label class="customLabel" for="IRR">IRR</label>
                </div>
                <div id="divIRR" class="col-xs-2">
                    <input type="text" class="form-control OnlyDecimal" id="IRR" />
                </div>
                <div class="col-xs-8"></div>
            </div>
            <div class="row customRow">
                <div class="col-xs-12">
                    <br>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <span class="custom-header">PAYBACK ITEMS</span>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <hr>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-12">
                    <div id="jsGridPaybackItems"></div>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-12">
                    <br>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <span class="custom-header">ONGOING COSTS</span>
                </div>
            </div>
            <div
                class="row">
                <div class="col-xs-12">
                    <hr>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-12">
                    <div id="jsGridOngoingCosts"></div>
                </div>
            </div>
        </div>
        <div id="tabs-6-COMMENTS">
            <div class="row">
                <div class="col-xs-12">
                    <uc1:CommentsCtrl runat="server" ID="comments" />
                </div>
            </div>
        </div>
        <div id="tabs-7-ATTACHMENTS">
            <div class="row">
                <div class="col-xs-12">
                    <span class="custom-header">ATTACHMENTS</span>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <hr>
                </div>
            </div>
            <div class="row customRow">
                <div class="ccool-xs-12">

                    <dx:ASPxFileManager
                        runat="server"
                        ID="fmAttachments"
                        Settings-AllowedFileExtensions=".pdf, .xls, .doc, .xlsx, .jpg, .png, .xlsm, .txt, .zip, .docx, .htm, .msg, .pptx, .tif, .ppt"
                        ClientInstanceName="fmAttachments"
                        OnFileUploading="fmAttachments_FileUploading"
                        OnItemDeleting="fmAttachments_ItemDeleting"
                        Height="600"
                        OnDetailsViewCustomColumnDisplayText="fmAttachments_CustomDisplay">

                        <ClientSideEvents FilesUploading="function(s, e) { lpSpinner.SetText('Uploading...'); lpSpinner.Show(); }"
                            FilesUploaded="function(s, e) { lpSpinner.Hide(); }"
                            CustomCommand="function(s, e) { switch (e.commandName) { case 'Select-All': toggleFileSelect(); break; } }" />
                        <SettingsDataSource />
                        <SettingsEditing AllowDownload="true" AllowDelete="true" />
                        <SettingsFolders Visible="false" />
                        <SettingsToolbar ShowPath="false" />
                        <SettingsToolbar>
                            <Items>
                                <dx:FileManagerToolbarRefreshButton BeginGroup="false" />
                                <dx:FileManagerToolbarDownloadButton BeginGroup="false" />
                                <dx:FileManagerToolbarCustomButton ToolTip="Select/Unselect all" CommandName="Select-All" GroupName="ViewMode">
                                    <Image IconID="actions_selectall_16x16office2013" />
                                </dx:FileManagerToolbarCustomButton>
                            </Items>
                        </SettingsToolbar>
                        <Settings EnableMultiSelect="true" />
                        <Settings AllowedFileExtensions=".pdf, .xls, .doc, .xlsx, .jpg, .png, .xlsm, .txt, .zip, .docx, .htm, .msg, .pptx, .tif, .ppt"></Settings>

                        <SettingsFileList View="Details">
                            <ThumbnailsViewSettings ThumbnailHeight="50" ThumbnailWidth="50" />
                        </SettingsFileList>
                    </dx:ASPxFileManager>
                </div>
            </div>
        </div>
        <div id="tabs-8-WORKFLOW">
            <div class="row">
                <div class="col-xs-12">
                    <span class="custom-header">ASSIGNMENT LIST</span>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <hr>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <div id="jsGridAssignmentList"></div>
                </div>
            </div>
        </div>
        <div id="tabs-9-RACI">
            <div class="row">
                <div class="col-xs-12">
                    <span class="custom-header">RACI</span>
                </div>
            </div>
            <div class="row">
                <div class="col-xs-12">
                    <hr>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-12">
                    <input type="button" value="Reload RACI" title="Reload RACI" onclick="populateRaciTab();" />&nbsp;&nbsp;<span>Click the "Reload RACI" button to view the latest RACI configuration and status.</span>
                </div>
            </div>
            <div class="row customRow">
                <div class="col-xs-12">
                    <span id="spanRaci"></span>
                </div>
            </div>
        </div>
    </div>


    <div id="divUserDetailsPopup" style="display: none; max-height: 400px; overflow-y: auto;">
        <div style="max-height: 400px; overflow-y: scroll;"><span id="divUserDetailsPopup-Content"></span></div>
    </div>


    <dx:ASPxPopupControl
        ID="PopupCARSubmitted"
        ClientInstanceName="PopupCARSubmitted"
        HeaderText="CAR Submitted"
        runat="server"
        AllowDragging="True"
        AllowResize="True"
        CloseAction="CloseButton"
        EnableViewState="False"
        PopupHorizontalAlign="WindowCenter"
        PopupVerticalAlign="Middle"
        ShowFooter="false"
        ShowOnPageLoad="false"
        Width="500px"
        Height="325px"
        MinWidth="310px"
        MinHeight="280px"
        CloseOnEscape="true"
        ContentUrl="/CARPopupInfo.aspx">
        <ClientSideEvents Closing="OnPopupClosing" />
    </dx:ASPxPopupControl>


</asp:Content>

