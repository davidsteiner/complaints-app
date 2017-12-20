from django.contrib.auth.models import User
import logging
from rest_framework import permissions, serializers
from rest_framework.response import Response
import rest_framework.status as status
from rest_framework.views import APIView


logger = logging.getLogger(__name__)


def jwt_response_payload_handler(token, user=None, request=None):
    return {
        'user': {
            'token': token,
            'username': user.username,
            'firstName': user.first_name,
            'email': user.email
        }
    }


class UserSerializer(serializers.ModelSerializer):

    password = serializers.CharField(write_only=True)

    def create(self, validated_data):

        user = User.objects.create(
            username=validated_data['username'],
            first_name=validated_data['first_name'],
            email=validated_data['email']
        )
        user.set_password(validated_data['password'])
        user.save()

        return user

    class Meta:
        model = User
        fields = ('username', 'first_name', 'email', 'password')


class Register(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request, format=None):
        serialized = UserSerializer(data=request.data)
        if serialized.is_valid():
            serialized.save()
            logger.warning('Replying = {}'.format(serialized.data))
            return Response({'user': serialized.data}, status=status.HTTP_200_OK)
        return Response(status=status.HTTP_400_BAD_REQUEST)
