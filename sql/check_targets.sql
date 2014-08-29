/* sysdate -1 can be changed to go back further

EM 12c: Enterprise Manager 12.1.0.2 Cloud Control Showing Alert: Count Of Targets Not Uploading Exceeded The Critical Threshold (0). Current Value: 1 Errors [ID 1532170.1]	


From 12.1.0.2 Cloud Control getting a lot of alerts and emails with following message:
Count of targets not uploading exceeded the critical threshold (0). Current value: 1 errors

Solution

At present 'Count of Targets not Uploading' agent side metric is sending false alarm. This is sending alerts based on targets not uploading for greater than 4 hours. This may not be a real issue. So following Enhancement Request is raised to address the issue:

BUG 14335948 - REVIEWING: NEW METRIC NEEDED TO DETERMINE TARGET UPLOAD STATUS

So you need to disable this metric for all 12.1.0.2 agents using either of the following methods:

* From Cloud Control navigate to :
Setup >  Manage Cloud Control > Agents.
Click on any of the agent link and then navigate to :
Agent >  Monitoring > Metric and Collection Settings. Now Click on collection schedule link for metric "Count of targets not uploading data"  and click Disable. Complete the wizard 

*/
 


SELECT t.target_name as target_name, t.target_type as target_type, t.emd_url
as emd_url,
CASE ca.current_status
WHEN 0 THEN 'Down'
END AS current_status,
null as metric_name, null as coll_name, null AS
collection_timestamp
FROM mgmt_targets t
JOIN mgmt_current_availability ca
ON ca.target_guid = t.target_guid
WHERE target_type = 'host'
AND ca.current_status = 0
UNION
SELECT t.target_name as target_name, t.target_type as target_type, t.emd_url
as emd_url,
CASE ca.current_status
WHEN 0 THEN 'Down'
WHEN 1 THEN 'Up'
WHEN 2 THEN 'Availability Evaluation Error'
WHEN 3 THEN 'Agent Down'
WHEN 4 THEN 'Agent Unreachable'
WHEN 5 THEN 'Blackout'
WHEN 6 THEN 'Status Pending'
END AS current_status,
m.metric_name as metric_name, me.coll_name as coll_name,
MAX(me.collection_timestamp) AS
collection_timestamp
FROM mgmt_metric_errors me
JOIN mgmt_targets t
ON me.target_guid = t.target_guid
JOIN mgmt_current_availability ca
ON t.target_guid = ca.target_guid
JOIN mgmt_metrics m
ON me.metric_guid = m.metric_guid
WHERE me.error_clear_timestamp IS NULL
AND me.collection_timestamp > sysdate - 1
GROUP BY
m.metric_name,me.coll_name,t.target_guid,t.target_name,t.target_type,t.emd_url
,ca.current_status;
