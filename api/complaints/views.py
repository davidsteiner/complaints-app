from complaints.models import Complaint, ComplaintSerializer, Message, MessageSerializer
from rest_framework import permissions
from rest_framework.response import Response
import rest_framework.status as status
from rest_framework.views import APIView


class ComplaintView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, format=None):
        serialized = ComplaintSerializer(data=request.data)
        if serialized.is_valid():
            complaint = serialized.save(owner=request.user)
            msg = Message(sender=request.user, text=request.data['message'], complaint=complaint)
            msg.save()
            return Response(serialized.data, status=status.HTTP_200_OK)
        return Response(status=status.HTTP_400_BAD_REQUEST)


class AllComplaintsView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request, format=None):
        complaints = Complaint.objects.filter(owner=request.user)
        serializer = ComplaintSerializer(complaints, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class ConversationView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request, conversation_id, format=None):
        complaint = Complaint.objects.get(id=int(conversation_id))
        if complaint and complaint.owner == request.user:
            messages = Message.objects.filter(complaint=complaint)
            message_serializer = MessageSerializer(messages, many=True)
            complaint_serializer = ComplaintSerializer(complaint)
            response = {'complaint': complaint_serializer.data, 'messages': message_serializer.data}
            return Response(response, status=status.HTTP_200_OK)
        return Response([], status=status.HTTP_404_NOT_FOUND)