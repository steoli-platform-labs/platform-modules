import boto3
import os
from datetime import datetime, time
import dateutil.tz


# -------------------------------------------------------------------------------------------------
# Init
# -------------------------------------------------------------------------------------------------
# Current region and account
session = boto3.session.Session()
region = session.region_name
account_id = boto3.client('sts').get_caller_identity()['Account']

# Get vars
timezone = os.environ['TIMEZONE']       # <continent>/<city>
tag = os.environ['TAG']                 # key:value
dryrun = os.environ['DRYRUN']           # "true" or "false"


# -------------------------------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------------------------------
def lambda_handler(event, context):

  action = event['action']

  # Boto init
  boto = Boto3Connection(region, account_id, dryrun)

  # Define scheduler message tag key
  msg_key = (f"{tag.split(':')[0]}Message")

  # Get current time
  tz = dateutil.tz.gettz(timezone)
  now = datetime.now(tz=tz)
  timestamp=now.strftime('%Y-%m-%d %H:%M')

  # Get EC2, RDS & ASG instances in scope using tag
  running_ec2, stopped_ec2 = boto.get_EC2(tag)
  running_rds, stopped_rds = boto.get_RDS(tag)
  running_asg, stopped_asg = boto.get_ASG(tag)

  if dryrun.lower() == "true":
    print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
    print("- - - - - - - - - - - - - - - - - DRY RUN !!! - - - - - - - - - - - - - - - - - ")
    print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
    print("No real stop or start will happend, only logging and tagging will be performed!")

  # Stop / Start
  if action == "start":
    print(f"Starting instances at {timestamp}")
    if stopped_rds:
      #boto.tag_RDS(stopped_rds, msg_key, f"Started at {timestamp}")
      boto.start_RDS(stopped_rds)
    if stopped_ec2:
      #boto.tag_EC2(stopped_ec2, msg_key, f"Started at {timestamp}")
      boto.start_EC2(stopped_ec2)
    if stopped_asg:
      #boto.tag_ASG(stopped_asg, msg_key, f"Started at {timestamp}")
      boto.start_ASG(stopped_asg)

  elif action == "stop":
    print(f"Stopping instances at {timestamp}")
    if running_ec2:
      #boto.tag_EC2(running_ec2, msg_key, f"Stopped at {timestamp}")
      boto.stop_EC2(running_ec2)
    if running_rds:
      #boto.tag_RDS(running_rds, msg_key, f"Stopped at {timestamp}")
      boto.stop_RDS(running_rds)
    if running_asg:
      #boto.tag_ASG(running_asg, msg_key, f"Stopped at {timestamp}")
      boto.stop_ASG(running_asg)

  else:
    print("Unknown action received, dont know what todo ¯\_(ツ)_/¯")


# -------------------------------------------------------------------------------------------------
# Boto3Connection
# -------------------------------------------------------------------------------------------------
class Boto3Connection:
  """
    Class holding the connection to AWS using boto3.
  """

  def __init__(self, region, account_id, dryrun):
    """
      Init boto clients and variables
    """
    self.__region = region
    self.__account_id = account_id
    self.__dryrun = dryrun.lower()
    self.__ec2 = boto3.client('ec2', region_name=region)
    self.__rds = boto3.client('rds', region_name=region)
    self.__autoscaling = boto3.client('autoscaling', region_name=region)


  def tag_EC2(self, Resources, Key, Value):
    """
      Adds stop/start timstamp tag to EC2 instances
    """
    response = self.__ec2.create_tags(
      Resources = Resources,
      Tags = [
        {
          'Key': Key,
          'Value': Value
        },
      ]
    )


  def tag_RDS(self, ResourceNames, Key, Value):
    """
      Adds stop/start timstamp tag to RDS instances
    """
    for ResourceName in ResourceNames:
      response = self.__rds.add_tags_to_resource(
        ResourceName=f"arn:aws:rds:{self.__region}:{self.__account_id}:db:{ResourceName}",
        Tags=[
          {
            'Key': Key,
            'Value': Value
          }
        ]
      )


  def tag_ASG(self, ResourceIds, Key, Value):
    """
      Adds stop/start timstamp tag to ASG
    """
    for ResourceId in ResourceIds:
      response = self.__autoscaling.create_or_update_tags(
        Tags = [
          {
            'ResourceId': ResourceId,
            'ResourceType': 'auto-scaling-group',
            'Key': Key,
            'Value': Value,
            'PropagateAtLaunch': True
          },
        ]
      )


  def get_ASG(self, ScheduleTag):
    """
      Scans trough ASG resources using tags to fetch candidates, returns a list of ASG ids
    """
    schedule_tag = ScheduleTag.split(":")
    running_asg_names = []
    stopped_asg_names = []
    autoscalinggroups = self.__autoscaling.describe_auto_scaling_groups(
      Filters=[
        {
          'Name': 'tag:' + schedule_tag[0],
          'Values': [
            schedule_tag[1]
          ]
        }
      ])['AutoScalingGroups']

    for autoscalinggroup in autoscalinggroups:
      if autoscalinggroup['DesiredCapacity'] != 0:
        running_asg_names.append(autoscalinggroup['AutoScalingGroupName'])
      if autoscalinggroup['DesiredCapacity'] == 0:
        stopped_asg_names.append(autoscalinggroup['AutoScalingGroupName'])

    return running_asg_names, stopped_asg_names


  def get_EC2(self, ScheduleTag):
    """
      Scans trough EC2 resources using tags to fetch candidates, returns a list of instance ids
    """
    schedule_tag = ScheduleTag.split(":")
    running_instance_ids = []
    stopped_instance_ids = []
    reservations = self.__ec2.describe_instances(
      Filters=[
        {
          'Name': 'tag:' + schedule_tag[0],
          'Values': [
            schedule_tag[1]
          ]
        }
      ])['Reservations']

    for reservation in reservations:
      instances = reservation['Instances']
      for instance in instances:
        if instance['State']['Name'] == "running":
          running_instance_ids.append(instance['InstanceId'])
        if instance['State']['Name'] == "stopped":
          stopped_instance_ids.append(instance['InstanceId'])
    
    return running_instance_ids, stopped_instance_ids


  def get_tags_for_db(self, db):
    """
      Get all tags from a specific DB instance, returns a list of instance tags
    """
    db_instance_arn = db['DBInstanceArn']
    db_instance_tags = self.__rds.list_tags_for_resource(ResourceName=db_instance_arn)
    return db_instance_tags['TagList']


  def get_RDS(self, ScheduleTag):
    """
      Scans trough RDS resources using tags to fetch candidates, returns a list of instance ids
    """
    schedule_tag = ScheduleTag.split(":")
    running_instance_ids = []
    stopped_instance_ids = []
    db_instances = self.__rds.describe_db_instances()['DBInstances']
    for db_instance in db_instances:
      db_instance_tags = self.get_tags_for_db(db_instance)
      response = next(iter(filter(lambda tag: tag['Key'] == schedule_tag[0] and tag['Value'] == schedule_tag[1], db_instance_tags)), None)

      if response:
        if db_instance['DBInstanceStatus'] ==  "available":
          running_instance_ids.append(db_instance['DBInstanceIdentifier'])
        if db_instance['DBInstanceStatus'] ==  "stopped":
          stopped_instance_ids.append(db_instance['DBInstanceIdentifier'])

    return running_instance_ids, stopped_instance_ids


  def start_EC2(self, InstanceIds):
    """
      Start EC2
    """
    if self.__dryrun != "true":
      response = self.__ec2.start_instances(InstanceIds=InstanceIds)
    print("Started EC2: {}".format(','.join(InstanceIds)))
    
  def stop_EC2(self, InstanceIds):
    """
      Stop EC2
    """
    if self.__dryrun != "true":
      response = self.__ec2.stop_instances(InstanceIds=InstanceIds)
    print("Stopped EC2: {}".format(','.join(InstanceIds)))


  def start_RDS(self, DBInstanceIdentifiers):
    """
      Start RDS
    """
    if self.__dryrun != "true":
      for DBInstanceIdentifier in DBInstanceIdentifiers:
        response = self.__rds.start_db_instance(DBInstanceIdentifier=DBInstanceIdentifier)

      # wait until "db_instance_available", only checking last DB in list
      self.__rds.get_waiter('db_instance_available').wait(DBInstanceIdentifier=DBInstanceIdentifiers[-1])

    print("Started RDS: {}".format(','.join(DBInstanceIdentifiers)))
    
    
  def stop_RDS(self, DBInstanceIdentifiers):
    """
      Stop RDS
    """
    if self.__dryrun != "true":
      for DBInstanceIdentifier in DBInstanceIdentifiers:
        response = self.__rds.stop_db_instance(DBInstanceIdentifier=DBInstanceIdentifier)

    print("Stopped RDS: {}".format(','.join(DBInstanceIdentifiers)))
 

  def start_ASG(self, AutoScalingGroupNames):
    """
      Start ASG
    """
    if self.__dryrun != "true":
      for AutoScalingGroupName in AutoScalingGroupNames:
        response = self.__autoscaling.set_desired_capacity(
          AutoScalingGroupName=AutoScalingGroupName,
          DesiredCapacity=1
        )
    
    print("Started ASG: {}".format(','.join(AutoScalingGroupNames)))
   
    
  def stop_ASG(self, AutoScalingGroupNames):
    """
      Stop ASG
    """
    if self.__dryrun != "true":
      for AutoScalingGroupName in AutoScalingGroupNames:
        response = self.__autoscaling.set_desired_capacity(
          AutoScalingGroupName=AutoScalingGroupName,
          DesiredCapacity=0
        )

    print("Stopped ASG: {}".format(','.join(AutoScalingGroupNames)))
