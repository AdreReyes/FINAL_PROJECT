resource "aws_cloudwatch_composite_alarm" "CPU_and_Mem" {
  alarm_description = "Composite alarm that monitors CPU Utilization and Memory"
  alarm_name        = "CPU_MEM_Composite_Alarm"
  alarm_actions = [module.sns_topic.CPU_MEM_topic.arn]

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.Grade-Tracker-ECS-High_CPU.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.Grade-Tracker-ECS-Low_CPU.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.Grade-Tracker-ECS-High_MEM.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.Grade-Tracker-ECS-Low_MEM.alarm_name})"


  depends_on = [
    aws_cloudwatch_metric_alarm.Grade-Tracker-ECS-High_CPU,
    aws_cloudwatch_metric_alarm.Grade-Tracker-ECS-Low_CPU,
    aws_cloudwatch_metric_alarm.Grade-Tracker-ECS-High_MEM,
    aws_cloudwatch_metric_alarm.Grade-Tracker-ECS-Low_MEM,
    aws_sns_topic.CPU_MEM_topic,
    aws_sns_topic_subscription.email-target
  ]
}

resource "aws_sns_topic" "CPU_MEM_topic" {
  name = "CPU_MEM_topic"
}
 
#Grade_Tracker_Resources

# resource "aws_sns_topic" "topic" {
#   name = "topic-name"
# }

resource "aws_sns_topic_subscription" "email-target" {
  topic_arn = module.sns_topic.CPU_MEM_topic.arn
  protocol  = "email"
  endpoint  = "teamfranns@gmail.com"

  depends_on = [
    module.sns_topic.CPU_MEM_topic
  ]
}


# Cloudwatch Alarm for ECS Cluster

resource "aws_cloudwatch_metric_alarm" "ecs-alert_High-CPUReservation" {
  alarm_name = "Grade-Tracker-ECS-High_CPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  # second
  statistic = "Average"
  threshold = "80"
  alarm_description = ""

  metric_name = "CPU_High_Usage"
  namespace = "AWS/ECS"
  dimensions = {
    ClusterName = "final-project-ecs-service-staging"
  }

  actions_enabled = true
  insufficient_data_actions = []
  alarm_actions       = [module.sns_topic.CPU_MEM_topic]
  ok_actions          = [module.sns_topic.CPU_MEM_topic]
}

resource "aws_cloudwatch_metric_alarm" "ecs-alert_Low-CPUReservation" {
  alarm_name = "Grade-Tracker-ECS-Low_CPU"
  comparison_operator = "LessThanThreshold"

  period = "300"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Average"
  threshold = "10"
  alarm_description = ""

  metric_name = "CPU_Low_Usage"
  namespace = "AWS/ECS"
  dimensions = {
    ClusterName = "final-project-ecs-service-staging"
  }

  actions_enabled = true
  insufficient_data_actions = []
  alarm_actions       = [module.sns_topic.CPU_MEM_topic]
  ok_actions          = [module.sns_topic.CPU_MEM_topic]
}

resource "aws_cloudwatch_metric_alarm" "ecs-alert_High-MemReservation" {
  alarm_name = "Grade-Tracker-ECS-High_MEM"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  period = "60"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Average"
  threshold = "80"
  alarm_description = ""

  metric_name = "Memory_High_Usage"
  namespace = "AWS/ECS"
  dimensions = {
    ClusterName = "final-project-ecs-service-staging"
  }

  actions_enabled = true
  insufficient_data_actions = []
  alarm_actions       = [module.sns_topic.CPU_MEM_topic]
  ok_actions          = [module.sns_topic.CPU_MEM_topic]
}

resource "aws_cloudwatch_metric_alarm" "ecs-alert_Low-MemReservation" {
  alarm_name = "Grade-Tracker-ECS-Low_MEM"
  comparison_operator = "LessThanThreshold"

  period = "300"
  evaluation_periods = "1"
  datapoints_to_alarm = 1

  statistic = "Average"
  threshold = "40"
  alarm_description = ""

  metric_name = "Memory_Low_Usage"
  namespace = "AWS/ECS"
  dimensions = {
    ClusterName = "final-project-ecs-service-staging"
  }

  actions_enabled = true
  insufficient_data_actions = []
  alarm_actions       = [module.sns_topic.CPU_MEM_topic]
  ok_actions          = [module.sns_topic.CPU_MEM_topic]
}

# Cloudwatch Alarm for ASG (of ECS Cluster)

# resource "aws_cloudwatch_metric_alarm" "ecs-asg-alert_Has-SystemCheckFailure" {
#   alarm_name = "${var.company}/${var.project}-ECS-Has_SysCheckFailure"
#   comparison_operator = "GreaterThanOrEqualToThreshold"

#   period = "60"
#   evaluation_periods = "1"
#   datapoints_to_alarm = 1

#   # second
#   statistic = "Sum"
#   threshold = "1"
#   alarm_description = ""

#   metric_name = "StatusCheckFailed"
#   namespace = "AWS/EC2"
#   dimensions = {
#     AutoScalingGroupName = "${aws_autoscaling_group.ecs.name}"
#   }

#   actions_enabled = true
#   insufficient_data_actions = []
#   ok_actions = []
#   alarm_actions = [
#     "${var.sns_topic_cloudwatch_alarm_arn}",
#   ]
# }




resource "aws_cloudwatch_composite_alarm" "EC2_and_EBS" {
  alarm_description = "Composite alarm that monitors CPUUtilization and EBS Volume Write Operations"
  alarm_name        = "EC2_&EBS_Composite_Alarm"
  alarm_actions = [aws_sns_topic.EC2_and_EBS_topic.arn]

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.EC2_CPU_Usage_Alarm.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.EBS_WriteOperations.alarm_name})"


  depends_on = [
    aws_cloudwatch_metric_alarm.EC2_CPU_Usage_Alarm,
    aws_cloudwatch_metric_alarm.EBS_WriteOperations,
    aws_sns_topic.EC2_and_EBS_topic,
    aws_sns_topic_subscription.EC2_and_EBS_Subscription
  ]
}


resource "aws_cloudwatch_metric_alarm" "EC2_CPU_Usage_Alarm" {
  alarm_name          = "EC2_CPU_Usage_Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ec2 cpu utilization exceeding 70%"
}


resource "aws_cloudwatch_metric_alarm" "EBS_WriteOperations" {
  alarm_name          = "EBS_WriteOperations"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "VolumeReadOps"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "1000"
  alarm_description   = "This monitors the average read operations on EBS Volumes in a specified period of time"
}


resource "aws_sns_topic" "EC2_and_EBS_topic" {
  name = "EC2_and_EBS_topic"
}

resource "aws_sns_topic_subscription" "EC2_and_EBS_Subscription" {
  topic_arn = aws_sns_topic.EC2_and_EBS_topic.arn
  protocol  = "email"
  endpoint  = "kelvingalabuzi@gmail.com"

  depends_on = [
    aws_sns_topic.EC2_and_EBS_topic
  ]
}