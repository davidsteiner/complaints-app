from complaints.models import Complaint
from rest_framework import permissions, serializers
from rest_framework.response import Response
import rest_framework.status as status
from rest_framework.views import APIView


class ComplaintView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request, format=None):
        serialized = ComplaintSerializer(data=request.data)
        if serialized.is_valid():
            serialized.save(owner=request.user)
            return Response({'complaint': serialized.data}, status=status.HTTP_200_OK)
        return Response(status=status.HTTP_400_BAD_REQUEST)


class ComplaintSerializer(serializers.ModelSerializer):

    def create(self, validated_data):

        complaint = Complaint.objects.create(
            owner=validated_data['owner'],
            subject=validated_data['subject']
        )
        complaint.save()

        return complaint

    class Meta:
        model = Complaint
        fields = ('subject', )
