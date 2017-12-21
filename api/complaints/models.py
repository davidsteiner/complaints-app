from django.contrib import admin
from django.contrib.auth.models import User
from django.db import models
from rest_framework import serializers


class Complaint(models.Model):

    owner = models.ForeignKey(User, on_delete=models.CASCADE)
    subject = models.CharField(max_length=30)


class Message(models.Model):

    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    complaint = models.ForeignKey(Complaint, on_delete=models.CASCADE)
    text = models.CharField(max_length=4096)

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
        fields = ('subject', )
