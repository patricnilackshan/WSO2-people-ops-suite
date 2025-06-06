// Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
import ballerina/sql;

# Query to retrieve work policies.
#
# + companyName - Company name to filter
# + return - Select query for the work policies
isolated function fetchWorkPoliciesQuery(string? companyName) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery mainQuery = `
    SELECT
        company_name AS 'companyName',
        ot_hours_per_year AS 'otHoursPerYear',
        working_hours_per_day AS 'workingHoursPerDay',
        lunch_hours_per_day AS 'lunchHoursPerDay'
    FROM
        work_policy
`;
    sql:ParameterizedQuery[] filters = [];
    if companyName is string {
        filters.push(sql:queryConcat(`company_name = `, `${companyName};`));
    }
    return buildSqlSelectQuery(mainQuery, filters);
}

# Query to update work policy of a company.
#
# + updateRecord - Update record type of the work policy
# + return - Update query for a work policy record
isolated function updateWorkPolicyQuery(WorkPolicyUpdatePayload updateRecord)
    returns sql:ParameterizedQuery {

    sql:ParameterizedQuery updateQuery = `
    UPDATE work_policy SET
`;
    updateQuery = sql:queryConcat(updateQuery, `ot_hours_per_year = COALESCE(${updateRecord.otHoursPerYear},
            ot_hours_per_year),`);
    updateQuery = sql:queryConcat(updateQuery, `working_hours_per_day = COALESCE(${updateRecord.workingHoursPerDay},
            working_hours_per_day),`);
    updateQuery = sql:queryConcat(updateQuery, `lunch_hours_per_day = COALESCE(${updateRecord.lunchHoursPerDay},
            lunch_hours_per_day),`);
    updateQuery = sql:queryConcat(updateQuery, `wp_updated_by = COALESCE(${updateRecord.updatedBy},
            wp_updated_by) WHERE company_name = ${updateRecord.companyName}`);
    return updateQuery;
}

# Query to retrieve the timesheet records of an employee.
#
# + filter - Filter type for the  records
# + return - Select query timesheet records
isolated function fetchTimeLogsQuery(TimeLogFilter filter) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery mainQuery = `
    SELECT
        tr.record_id AS recordId,
        tr.employee_email AS employeeEmail,
        tr.record_date AS recordDate,
        tr.clock_in AS clockInTime,
        tr.clock_out AS clockOutTime,
        tr.lunch_included AS isLunchIncluded,
        tr.ot_hours AS overtimeDuration,
        tr.ot_reason AS overtimeReason,
        tr.ot_rejection_reason AS overtimeRejectReason,
        tr.time_log_status AS timeLogStatus
    FROM
        time_log tr
    `;
    sql:ParameterizedQuery[] filters = [];
    if filter.employeeEmail is string {
        filters.push(sql:queryConcat(`tr.employee_email = `, `${filter.employeeEmail}`));
    }
    if filter.recordDates is string[] {
        filters.push(sql:queryConcat(`tr.record_date IN (`, sql:arrayFlattenQuery(filter.recordDates ?: []), `)`));
    }
    if filter.recordIds is int[] {
        filters.push(sql:queryConcat(`tr.record_id IN (`, sql:arrayFlattenQuery(filter.recordIds ?: []), `)`));
    }
    if filter.status is TimeLogStatus {
        filters.push(sql:queryConcat(`tr.time_log_status =  `, `${filter.status}`));
    }
    if filter.rangeStart is string {
        filters.push(sql:queryConcat(`tr.record_date >= ${filter.rangeStart}`));
    }
    if filter.rangeEnd is string {
        filters.push(sql:queryConcat(`tr.record_date <= ${filter.rangeEnd}`));
    }
    if filter.leadEmail is string {
        filters.push(sql:queryConcat(`tr.lead_email =  `, `${filter.leadEmail}`));
    }
    mainQuery = buildSqlSelectQuery(mainQuery, filters);
    mainQuery = sql:queryConcat(mainQuery, `ORDER BY record_date DESC`);
    if filter.recordsLimit is int {
        mainQuery = sql:queryConcat(mainQuery, ` LIMIT ${filter.recordsLimit}`);
        if filter.recordOffset is int {
            mainQuery = sql:queryConcat(mainQuery, ` OFFSET ${filter.recordOffset}`);
        }
    } else {
        mainQuery = sql:queryConcat(mainQuery, ` LIMIT 500`);
    }
    return mainQuery;
}

# Query to retrieve the timesheet record count of an employee.
#
# + filter - Filter type for the records
# + return - Select query to get total count of timesheet records
isolated function fetchTimeLogCountQuery(TimeLogFilter filter) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery mainQuery = `
        SELECT
            COUNT(*) AS totalRecords
        FROM
            time_log
    `;
    sql:ParameterizedQuery[] filters = [];
    if filter.employeeEmail is string {
        filters.push(sql:queryConcat(`employee_email = `, `${filter.employeeEmail}`));
    }
    if filter.status is TimeLogStatus {
        filters.push(sql:queryConcat(`time_log_status = `, `${filter.status}`));
    }
    if filter.leadEmail is string {
        filters.push(sql:queryConcat(`lead_email =  `, `${filter.leadEmail}`));
    }
    mainQuery = buildSqlSelectQuery(mainQuery, filters);
    return mainQuery;
}

# Query to insert the timesheet records of an employee.
#
# + payload - TimeLogCreatePayload to be inserted
# + return - Insert query for the timesheet records
isolated function insertTimeLogQueries(TimeLogCreatePayload payload) returns sql:ParameterizedQuery[] =>

            from TimeLog timesheetRecord in payload.timeLogs
let TimeLog {recordDate, clockInTime, clockOutTime, isLunchIncluded, overtimeDuration, overtimeReason,
timeLogStatus} = timesheetRecord
select `
        INSERT INTO time_log (
            employee_email,
            record_date,
            company_name,
            clock_in,
            clock_out,
            lunch_included,
            ot_hours,
            ot_reason,
            lead_email,
            time_log_status,
            created_by,
            updated_by
        )
        VALUES (
            ${payload.employeeEmail},
            ${recordDate},
            ${payload.companyName},
            ${clockInTime},
            ${clockOutTime},
            ${isLunchIncluded},
            ${overtimeDuration},
            ${overtimeReason},
            ${payload.leadEmail},
            ${timeLogStatus},
            ${payload.employeeEmail},
            ${payload.employeeEmail}
        );
    `;

# Query to retrieve timesheet information.
#
# + employeeEmail - Email of the employee
# + leadEmail - Email of the lead
# + return - Select query for the timesheet information
isolated function fetchTimeLogStatsQuery(string? employeeEmail, string? leadEmail) returns sql:ParameterizedQuery {
    sql:ParameterizedQuery mainQuery = `
    SELECT
        COALESCE(COUNT(*), 0) AS totalRecords,
        COALESCE(SUM(CASE
                    WHEN time_log_status = ${PENDING} THEN 1
                    ELSE 0
                END),
                0) AS pendingRecords,
        COALESCE(SUM(CASE
                    WHEN time_log_status = ${REJECTED} THEN 1
                    ELSE 0
                END),
                0) AS rejectedRecords,
        COALESCE(SUM(CASE
                    WHEN time_log_status = ${APPROVED} THEN 1
                    ELSE 0
                END),
                0) AS approvedRecords,
        COALESCE(SUM(CASE
                    WHEN time_log_status IN (${PENDING}, ${APPROVED}) THEN ot_hours
                    ELSE 0
                END),
                0) AS totalOvertimeTaken
    FROM
        time_log
    `;
    sql:ParameterizedQuery[] filters = [];
    if employeeEmail is string {
        filters.push(sql:queryConcat(`time_log.employee_email = `, `${employeeEmail}`));
    }
    if leadEmail is string {
        filters.push(sql:queryConcat(`time_log.lead_email =  `, `${leadEmail}`));
    }
    mainQuery = buildSqlSelectQuery(mainQuery, filters);
    return mainQuery;
}

# Query to retrieve overtime information.
#
# + companyName - Name of the company
# + employeeEmail - Email of the employee
# + startDate - Start date
# + endDate - End date
# + return - Select query for the overtime information
isolated function fetchOvertimeStatsQuery(string employeeEmail, string companyName, string startDate, string endDate)
    returns sql:ParameterizedQuery =>
`
    SELECT
        COALESCE(SUM(CASE
                    WHEN time_log_status IN (${PENDING}, ${APPROVED}) THEN ot_hours
                    ELSE 0
                END),
                0) AS totalOvertimeTaken,
        COALESCE((SELECT
                        ot_hours_per_year
                    FROM
                        work_policy
                    WHERE
                        company_name LIKE ${companyName}
                    LIMIT 1),
                0) AS otHoursPerYear,
        (COALESCE((SELECT
                        ot_hours_per_year
                    FROM
                        work_policy
                    WHERE
                        company_name LIKE ${companyName}
                    LIMIT 1),
                0) - COALESCE(SUM(CASE
                    WHEN time_log_status IN (${PENDING}, ${APPROVED}) THEN ot_hours
                    ELSE 0
                END),
                0)) AS overtimeLeft
    FROM
        time_log
    WHERE
        record_date >= ${startDate}
            AND record_date <= ${endDate}
            AND company_name LIKE ${companyName}
            AND employee_email = ${employeeEmail};
`;

# Query to update time logs.
#
# + payloadArray - Update payload
# + return - Update query for time logs
isolated function updateTimeLogsQuery(TimeLogUpdatePayload[] payloadArray) returns sql:ParameterizedQuery[] {
    sql:ParameterizedQuery[] updateQueries = [];
    foreach TimeLogUpdatePayload timeLog in payloadArray {

        sql:ParameterizedQuery updateQuery = `UPDATE time_log SET `;
        sql:ParameterizedQuery subQuery =
            `,updated_by = ${timeLog.updatedBy} WHERE record_id = ${timeLog.recordId};`;
        sql:ParameterizedQuery[] updateFilters = [];

        if timeLog.clockInTime is string {
            updateFilters.push(`clock_in = ${timeLog.clockInTime}`);
        }
        if timeLog.clockOutTime is string {
            updateFilters.push(`clock_out = ${timeLog.clockOutTime}`);
        }
        if timeLog.isLunchIncluded is int {
            updateFilters.push(`lunch_included = ${timeLog.isLunchIncluded}`);
        }
        if timeLog.overtimeDuration is decimal {
            updateFilters.push(`ot_hours = ${timeLog.overtimeDuration}`);
        }
        if timeLog.overtimeReason is string {
            updateFilters.push(`ot_reason = ${timeLog.overtimeReason}`);
        }
        if timeLog.overtimeRejectReason is string {
            updateFilters.push(`ot_rejection_reason = ${timeLog.overtimeRejectReason}`);
        }
        if timeLog.timeLogStatus is TimeLogStatus {
            updateFilters.push(`time_log_status = ${timeLog.timeLogStatus}`);
        }
        updateQuery = buildSqlUpdateQuery(updateQuery, updateFilters);
        updateQuery = sql:queryConcat(updateQuery, subQuery);
        updateQueries.push(updateQuery);
    }
    return updateQueries;
}
