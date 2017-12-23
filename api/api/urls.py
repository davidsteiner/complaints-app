from complaints.views import AllComplaintsView, ComplaintView, ConversationView, SendMessageView
from django.conf.urls import url, include
from django.contrib import admin
from django.views.generic.base import TemplateView
from rest_framework_jwt.views import obtain_jwt_token

import login_jwt.urls


urlpatterns = [
    url(r'^api/api-token-auth/', obtain_jwt_token),
    url(r'^admin/', admin.site.urls),
    url(r'^api/', include(login_jwt.urls)),
    url(r'api/new-complaint/', ComplaintView.as_view()),
    url(r'api/complaints/', AllComplaintsView.as_view()),
    url(r'api/conversation/(?P<conversation_id>\d+)/', ConversationView.as_view()),
    url(r'api/send-message/', SendMessageView.as_view()),
    url(r'^$', TemplateView.as_view(template_name='index.html'))
]
