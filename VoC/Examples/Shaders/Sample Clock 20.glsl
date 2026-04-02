#version 420

// original https://www.shadertoy.com/view/3djcDh

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define red vec3(1.0,0.0,0.0)
#define green vec3(0.0,1.0,0.0)
#define blue vec3(0.0,0.0,1.0)
#define yellow vec3(1.0,1.0,0.0)

const bool gradient = true; //if the lines should have rounded edges

vec4 BG() {
    vec4 rgi = mix(vec4(vec3(1.0,0.0,0.0),1.0), vec4(vec3(0.0,1.0,0.0),1.0), gl_FragCoord.xy.x/resolution.x);
    vec4 byi = mix(vec4(vec3(0.0,0.0,1.0),1.0), vec4(vec3(1.0,1.0,0.0),1.0), gl_FragCoord.xy.x/resolution.x);
    return mix(rgi, byi, gl_FragCoord.xy.y/resolution.y);
}

vec4 CombineLayers(vec4 topl, vec4 bottoml) {
    return mix(bottoml, topl, topl.a);
}

float DistLinePoint(vec2 P1, vec2 P2, vec2 P0) {
    return abs((P2.y-P1.y)*P0.x-(P2.x-P1.x)*P0.y+P2.x*P1.y-P1.x*P2.y)/sqrt(pow((P2.y-P1.y), 2.0)+pow((P2.x-P1.x),2.0));
}

float Line(vec2 L1, vec2 L2, float width) {
    float outval = 1.0;
    float lengthL = distance(L1, L2);
    
    float deltax = L1.x-L2.x;
    float deltay = L1.y-L2.y;
    
    vec2 borderPoint1 = vec2(L1.x+deltay, L1.y-deltax);
    vec2 borderPoint2 = vec2(L2.x+deltay, L2.y-deltax);
    
    if (max(DistLinePoint(L1, borderPoint1, gl_FragCoord.xy), DistLinePoint(L2, borderPoint2, gl_FragCoord.xy)) > lengthL) {
        outval = min(distance(L1, gl_FragCoord.xy), distance(L2, gl_FragCoord.xy)) / width;
    } else {
        outval = DistLinePoint(L1, L2, gl_FragCoord.xy) / width;
    }
    if (gradient) {
        return min(1.0, 1.0 - outval);
    } else {
        if (1.0 - outval >= 0.5) {
            return 1.0;
        } else {
            return 0.0;
        }
    }
}
float Dot(float r, float width) {
    if (gradient) {
        return min(1.0, 1.0 - ( distance(resolution.xy/2.0, gl_FragCoord.xy) - r ) / width);
    } else {
        if (1.0 - ( distance(resolution.xy/2.0, gl_FragCoord.xy) - r ) / width >= 0.5) {
            return 1.0;
        } else {
            return 0.0;
        }
    }
}
float Circle(float r, float width) {
    if (gradient) {
        return min(1.0, 1.0 - abs( distance(resolution.xy/2.0, gl_FragCoord.xy) - r ) / width);
    } else {
        if (1.0 - abs( distance(resolution.xy/2.0, gl_FragCoord.xy) - r ) / width >= 0.5) {
            return 1.0;
        } else {
            return 0.0;
        }
    }
    
}
float CircleLine(float r, float angle, float width) {
    float deltax = sin(radians(angle))*r;
    float deltay = cos(radians(angle))*r;
    vec2 P2 = vec2((resolution.xy/2.0).x+deltax, (resolution.xy/2.0).y+deltay);
    return Line(resolution.xy/2.0, P2, width);
}
float CircleLineSegment(float r1, float r2, float angle, float width) {
    float deltax1 = sin(radians(angle))*r1;
    float deltay1 = cos(radians(angle))*r1;
    vec2 P1 = vec2((resolution.xy/2.0).x+deltax1, (resolution.xy/2.0).y+deltay1);
    
    float deltax2 = sin(radians(angle))*r2;
    float deltay2 = cos(radians(angle))*r2;
    vec2 P2 = vec2((resolution.xy/2.0).x+deltax2, (resolution.xy/2.0).y+deltay2);
    
    return Line(P1, P2, width);
}

float getHours() {
    return floor(date[3]/3600.0);
}
float getMinutes() {
    return floor((date[3]-getHours()*3600.0)/60.0);
}
float getSeconds() {
    return floor(date[3]-getHours()*3600.0-getMinutes()*60.0);
}

float HourHand() {
    return CircleLine(min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)/2.0, mod(30.0*getHours(), 360.0), min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*4.0/150.0);
}
float MinuteHand() {
    return CircleLine(min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*2.0/3.0, getMinutes()*6.0, min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*4.0/150.0);
}
float SecondHand() {
    return CircleLine(min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*22.0/30.0, getSeconds()*6.0, min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*2.0/150.0);
}

float HourMarks() {
    float maxVal = 0.0;
    for (int i = 0; i < 12; i++) {
        maxVal = max(maxVal, CircleLineSegment(min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*13.0/15.0, min(resolution.x*5.0/12.0, resolution.y/2.0-30.0), float(i)*30.0, min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*3.0/150.0));
    }
    return maxVal;
}
float MinuteMarks() {
    float maxVal = 0.0;
    for (int i = 0; i<60; i++) {
        if (mod(float(i), 5.0) != 0.0) {
            maxVal = max(maxVal, CircleLineSegment(min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*13.0/15.0, min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*27.0/30.0, float(i)*6.0, min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*3.0/150.0));
        }
    }
    return maxVal;
}

float Dial() {
    float circ = Circle(min(resolution.x*5.0/12.0, resolution.y/2.0-30.0), min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*3.0/150.0);
    float HourMarks = HourMarks();
    float MinuteMarks = MinuteMarks();
    float MiddleAxis = Dot(min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)/150.0, min(resolution.x*5.0/12.0, resolution.y/2.0-30.0)*4.0/150.0);
    return max(circ, max(HourMarks, max(MinuteMarks, MiddleAxis)));
}

void main(void) {
    float HourH = HourHand();
    float MinuteH = MinuteHand();
    float SecondH = SecondHand();
    float Dial = Dial();
    
    float mask = max(Dial, max(HourH, max(MinuteH, SecondH)));
    
    float circle = float(distance(resolution.xy/2.0, gl_FragCoord.xy) < min(resolution.x*5.0/12.0, resolution.y/2.0-30.0));
    
    glFragColor = CombineLayers(vec4(mask), BG()*(1.0-circle)+BG()*0.7*circle);
}
