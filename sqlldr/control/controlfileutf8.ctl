-- Control file import stage table
-- Ignore errors and continue
options (errors=999999999)

load data
characterset AL32UTF8
append
into table stage
-- Hex for |
fields terminated by X'7C'
-- optionally enclosed by '"'
trailing nullcols
(
row_num,
file_name,
file_chksum,
row_chksum,
import_dt,
permit_no,
contractor_name,
contractor_phone,
dept,
permit_issue_dt,
construct_value,
permit_fee,
no_units,
fee_sqft,
res_style,
parcel,
blueprint_code,
blueprint_number,
flood_ref,
low_address,
high_address,
direction,
street_name,
street_type,
suite,
city,
state,
zip,
schd,
project_code,
project_descr,
"COMMENT",
solar,
lot,
block,
zone,
subdivision,
utilities_ref,
gas_ref,
va_inspect,
rbd_inspect,
owner,
front_set,
rear_set,
side1_set,
side2_set,
permit_status,
ocupy_no,
co_date,
import_overflow
)
