from calendar import timegm
from datetime import datetime
from django.contrib.auth.models import User
import logging
from rest_framework import permissions, serializers
from rest_framework.response import Response
import rest_framework.status as status
from rest_framework.views import APIView
from rest_framework_jwt.settings import api_settings


logger = logging.getLogger(__name__)


def jwt_payload_hander(user):
    return {
        'username': user.username,
        'exp': datetime.utcnow() + api_settings.JWT_EXPIRATION_DELTA,
        'is_staff': user.is_staff,
        'orig_iat': timegm(datetime.utcnow().utctimetuple())
    }


class UserSerializer(serializers.ModelSerializer):

    password = serializers.CharField(write_only=True)
    email = serializers.EmailField(write_only=True, allow_blank=True)

    def create(self, validated_data):

        user = User.objects.create(
            username=validated_data['username'],
            email=validated_data['email']
        )
        user.set_password(validated_data['password'])
        user.save()

        return user

    class Meta:
        model = User
        fields = ('username', 'email', 'password')


class Register(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request, format=None):
        serialized = UserSerializer(data=request.data)
        if serialized.is_valid():
            serialized.save()
            logger.info('User registered: %s', serialized.data)
            return Response(serialized.data, status=status.HTTP_200_OK)
        return Response(status=status.HTTP_400_BAD_REQUEST)
