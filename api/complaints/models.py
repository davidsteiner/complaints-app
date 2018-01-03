from babel.dates import format_datetime
from django.contrib import admin
from django.contrib.auth.models import User
from django.db import models
import pytz
from rest_framework import serializers


class Complaint(models.Model):

    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    subject = models.CharField(max_length=30)
    created = models.DateTimeField(auto_now_add=True)


class Message(models.Model):

    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    complaint = models.ForeignKey(Complaint, on_delete=models.CASCADE)
    text = models.CharField(max_length=4096)
    created = models.DateTimeField(auto_now_add=True)

    def formatted_timestamp(self):
        budapest_time = self.created.astimezone(pytz.timezone('Europe/Budapest'))
        return format_datetime(budapest_time, locale='hu')


admin.site.register(Complaint)
admin.site.register(Message)


class ComplaintSerializer(serializers.ModelSerializer):

    owner = serializers.StringRelatedField(read_only=True)
    id = serializers.IntegerField(read_only=True)

    def create(self, validated_data):
        complaint = Complaint.objects.create(
            owner=validated_data['owner'],
            subject=validated_data['subject']
        )
        complaint.save()
        return complaint

    class Meta:
        model = Complaint
        fields = ('subject', 'owner', 'id')


class MessageSerializer(serializers.ModelSerializer):
    sender = serializers.StringRelatedField(read_only=True)
    created = serializers.ReadOnlyField(read_only=True, source='formatted_timestamp')

    def create(self, validated_data):
        complaint = Complaint.objects.get(pk=validated_data['complaint'])

        msg = Message.objects.create(
            sender=validated_data['sender'],
            complaint=complaint,
            text=validated_data['text']
        )
        msg.save()
        return msg

    def validate_complaint(self, attrs, source):
        if Complaint.objects.filter(pk=attrs[source]).exists():
            return attrs
        raise serializers.ValidationError('Complaint does not exist')

    class Meta:
        model = Message
        fields = ('text', 'sender', 'created')
