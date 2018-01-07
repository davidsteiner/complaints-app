from complaints.models import Complaint, ComplaintSerializer, Message, MessageSerializer
from django.conf import settings
from django.contrib.auth.models import User
from django.core.mail import send_mail
from rest_framework import permissions
from rest_framework.response import Response
import rest_framework.status as status
from rest_framework.views import APIView


def send_notification(complaint, message):
    recipients = []
    if message.sender == complaint.owner:
        # The sender of the message is the owner of the complaint, therefore we notify the admin users
        recipients = [user.email for user in User.objects.filter(is_staff=True) if user.email]
    elif complaint.owner.email:
        # The sender is not the owner, therefore it's a staff reply: we notify the owner of the complaint
        recipients = [complaint.owner.email]

    if recipients:
        send_mail("Message from {}".format(message.sender),
                  message.text,
                  settings.EMAIL_NOTIFIER_ADDRESS,
                  recipients,
                  fail_silently=True)


class ComplaintView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, format=None):
        serialized = ComplaintSerializer(data=request.data)
        if serialized.is_valid():
            complaint = serialized.save(owner=request.user)
            msg = Message(sender=request.user, text=request.data['message'], complaint=complaint)
            msg.save()

            send_notification(complaint, msg)

            return Response(serialized.data, status=status.HTTP_200_OK)
        return Response(status=status.HTTP_400_BAD_REQUEST)


class AllComplaintsView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request, format=None):
        complaints = Complaint.objects.all() if request.user.is_staff else Complaint.objects.filter(owner=request.user)
        serializer = ComplaintSerializer(complaints, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class ConversationView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request, conversation_id, format=None):
        try:
            complaint = Complaint.objects.get(id=int(conversation_id))

            if request.user.is_staff or (complaint and complaint.owner == request.user):
                return Response(get_serialized_conversation(complaint), status=status.HTTP_200_OK)
            else:
                return Response({'detail': 'You have no permission to view this conversation.'},
                                status=status.HTTP_401_UNAUTHORIZED)

        except Complaint.DoesNotExist:
            return Response([], status=status.HTTP_404_NOT_FOUND)


def get_serialized_conversation(complaint):
    messages = Message.objects.filter(complaint=complaint)
    message_serializer = MessageSerializer(messages, many=True)
    complaint_serializer = ComplaintSerializer(complaint)
    return {'complaint': complaint_serializer.data, 'messages': message_serializer.data}


class SendMessageView(APIView):

    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, format=None):
        complaint_id = request.data.get('complaint_id')
        message_text = request.data.get('text')

        if not complaint_id or not message_text:
            return Response(status=status.HTTP_400_BAD_REQUEST)

        complaint = Complaint.objects.get(id=int(complaint_id))
        if request.user.is_staff or (complaint and complaint.owner == request.user):
            msg = Message(sender=request.user, text=message_text, complaint=complaint)
            msg.save()

            send_notification(complaint, msg)

            return Response(get_serialized_conversation(complaint), status=status.HTTP_200_OK)

        return Response(status=status.HTTP_401_UNAUTHORIZED)
