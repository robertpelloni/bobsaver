#version 420

// original https://www.shadertoy.com/view/XtsfWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 currentCoords;

struct circle{
    vec2 m_Center;
    float m_Radius;
};
    
bool IsInside(circle _circle){
    float _magnitude = length(currentCoords.xy - _circle.m_Center);
    return _magnitude <= _circle.m_Radius;
}
bool IsLeft(vec2 _line){
    return cross(vec3(currentCoords, 0.0), vec3(_line, 0.0)).z >= 0.0;
}

vec2 Rotate(vec2 _vec, float _angle){
    return mat2(cos(_angle), -sin(_angle), sin(_angle), cos(_angle)) * _vec;
}

void main(void)
{
    currentCoords = gl_FragCoord.xy * 2.0 - resolution.xy;
    vec2 nResolution = resolution.xy * 2.0;
    vec2 upVector = vec2(0.0, 1.0);
    float gradient = -1.0 * ((length(currentCoords) / (length(nResolution) / 2.0)) - 1.0);
    
    circle yinYang = circle(vec2(0.0, 0.0), 0.9 * nResolution.y / 2.0);
    circle bigYin = circle(vec2(0.0, yinYang.m_Radius / 2.0), yinYang.m_Radius / 2.0);
    circle smallYin = circle(bigYin.m_Center, bigYin.m_Radius * 0.3);
    circle bigYang = circle(vec2(0.0, -yinYang.m_Radius / 2.0), yinYang.m_Radius / 2.0);
    circle smallYang = circle(bigYang.m_Center, bigYang.m_Radius * 0.3);
    
    bigYin.m_Center = Rotate(bigYin.m_Center, -time);
    smallYin.m_Center = Rotate(smallYin.m_Center, -time);
    bigYang.m_Center = Rotate(bigYang.m_Center, -time);
    smallYang.m_Center = Rotate(smallYang.m_Center, -time);
    upVector = Rotate(upVector, -time);
    
    if(!IsInside(yinYang)){
        glFragColor = vec4(gradient, 0.0, 0.0, 1.0);
    }else{
        if((IsInside(bigYin) && !IsInside(smallYin)) ||
           (!IsInside(bigYin) && !IsInside(bigYang) && IsLeft(upVector)) ||
           IsInside(smallYang)){
            glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
        }else{
            glFragColor = vec4(1.0, 1.0, 1.0, 1.0);
        }
    }
}
