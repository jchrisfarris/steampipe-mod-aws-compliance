with data as (
  select
    distinct name
  from
    aws_s3_bucket,
    jsonb_array_elements(acl -> 'Grants') as grants
  where
    (
      grants -> 'Grantee' ->> 'URI' = 'http://acs.amazonaws.com/groups/global/AllUsers'
      or grants -> 'Grantee' ->> 'URI' = 'http://acs.amazonaws.com/groups/global/AuthenticatedUsers'
    )
    and (
      grants ->> 'Permission' = 'FULL_CONTROL'
      or grants ->> 'Permission' = 'WRITE_ACP'
      or grants ->> 'Permission' = 'WRITE'
    )
  )
select
  -- Required Columns
  b.arn as resource,
  case
    when d.name is null then 'ok'
    else 'alarm'
  end status,
  case
    when d.name is null then b.title || ' not publicly writable.'
    else b.title || ' publicly writable.'
  end reason,
  -- Additional Dimensions
  b.region,
  b.account_id
from
  aws_s3_bucket as b
  left join data as d on b.name = d.name;
