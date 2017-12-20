from django.contrib.auth.models import User
from django.db import models


class Complaint(models.Model):

    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    subject = models.CharField(max_length=30)


class Message(models.Model):

    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    complaint = models.ForeignKey(Complaint, on_delete=models.CASCADE)
    text = models.CharField(max_length=4096)
