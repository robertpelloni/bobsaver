#version 420

// original https://www.shadertoy.com/view/fsccRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float xRatio;
float smoothSize = 0.001;
float l = 0.006;

// The image goes from 0.0 to 1.0 on each axes. rescale the coordinates
vec2 Point( in float x, in float y)
{
    return vec2(x*xRatio, y);
}

// If is iside the rectangle
bool isInside(in vec2 center, in float size, in vec2 x)
{
    vec2 bl = vec2(center.x - size, center.y - size);
    vec2 tr = vec2(center.x + size, center.y + size);
    return bl.x < x.x && bl.y < x.y && tr.x > x.x && tr.y > x.y;
}

// Draw a rectangle using bottomLeft and topRight point as data
float Rect(in vec2 a, in vec2 b, in vec2 x)
{
    
    float band1 = min(smoothstep(a.x-smoothSize, a.x+smoothSize, x.x), 1.0 - smoothstep(b.x-smoothSize, b.x+smoothSize, x.x));
    float band2 = min(smoothstep(a.y-smoothSize, a.y+smoothSize, x.y), 1.0 - smoothstep(b.y-smoothSize, b.y+smoothSize, x.y));
    
    return min(band1, band2);  
}

// Draw a square using 4 rectangles
float Square(in vec2 center, in float sideSize, vec2 x)
{
    vec2 tl = vec2(center.x - sideSize, center.y + sideSize);
    vec2 tr = vec2(center.x + sideSize, center.y + sideSize);
    vec2 bl = vec2(center.x - sideSize, center.y - sideSize);
    vec2 br = vec2(center.x + sideSize, center.y - sideSize);
    
    tl.y -= l;
    float tempRes = Rect(tl, tr, x);
    br.x -= l;
    tempRes = max(tempRes, Rect(br, tr, x));
    br.y += l;
    tempRes = max(tempRes, Rect(bl, br, x));
    tl.x += l; 
    return max(tempRes, Rect(bl, tl, x));
}

float firstSizeFunc(in float tf, in float ts, in float st)
{
    return sin(time + cos(time*tf+ts*st));
}
    
float secondSizeFunc(in float tf, in float ts, in float st)
{
    return sin(time*tf+ts*st);
}
    
float thirdSizeFunc(in float tf, in float ts, in float st)
{
    return cos(time*tf+ts*st);
}

void main(void)
{
    xRatio = resolution.x/resolution.y;
    vec2 coord = Point(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    
    // Final gray value
    float c = 0.0;
    
    vec2 center = Point(0.5, 0.5);
    
    // Main raw of squares data
    float xOffSet0 = 0.0;
    float yOffSet0 = 0.0;
    float baseSize0 = 0.01;
    float addedSize0 = 0.31;
    float timeFactor0 = 1.8;
    float timeStep0 = 0.15;
    
    // Second raw of squares data
    float xOffSet1 = 0.0;
    float yOffSet1 = 0.0;
    float baseSize1 = 0.085;
    float addedSize1 = 0.085;
    float timeFactor1 = 1.0;
    float timeStep1 = 0.1;
    
    // Third raw of squares data
    float xOffSet2 = 0.0;
    float yOffSet2 = 0.0;
    float baseSize2 = 0.04;
    float addedSize2 = 0.04;
    float timeFactor2 = 1.5;
    float timeStep2 = 0.15;
    
    
    
    for(float i=9.0; i>0.0; i--)
    {
        // First Squares
        vec2 firstCenter = center;
        float firstSize = baseSize0 + addedSize0*firstSizeFunc(timeFactor0, timeStep0, i);
        float secondSize = baseSize1 + addedSize1*secondSizeFunc(timeFactor1, timeStep1, i);
        float thirdSize = baseSize2 + addedSize2*thirdSizeFunc(timeFactor2, timeStep2, i);
        if (isInside(firstCenter, firstSize, coord)){
            c += Square(firstCenter, firstSize, coord);
            i = -1.0;}
        // If not inside a first squares
        // tries to draw secondes
        else{
            vec2 tl; vec2 tr; vec2 br; vec2 bl;
            
            tl = vec2(firstCenter.x - firstSize, firstCenter.y + firstSize);
            if (isInside(tl, secondSize, coord)){
                c += Square(tl, secondSize, coord);
                i = -1.0;}
            else{
                
                vec2 secondCenter = tl;
                tl = vec2(secondCenter.x - secondSize, secondCenter.y + secondSize);
                
                if (isInside(tl, thirdSize, coord)){
                    c += Square(tl, thirdSize, coord);
                    i = -1.0;}
                tr = vec2(secondCenter.x + secondSize, secondCenter.y + secondSize);
                if (isInside(tr, thirdSize, coord)){
                    c += Square(tr, thirdSize, coord);
                    i = -1.0;}
                bl = vec2(secondCenter.x - secondSize, secondCenter.y - secondSize);
                if (isInside(bl, thirdSize, coord)){
                    c += Square(bl, thirdSize, coord);
                    i = -1.0;}
                br = vec2(secondCenter.x + secondSize, secondCenter.y - secondSize);
                if (isInside(br, thirdSize, coord)){
                    c += Square(br, thirdSize, coord);
                    i = -1.0;} 
            }
            
            
            tr = vec2(firstCenter.x + firstSize, firstCenter.y + firstSize);
            if (isInside(tr, secondSize, coord)){
                c += Square(tr, secondSize, coord);
                i = -1.0;}
            else{
                vec2 secondCenter = tr;
                tl = vec2(secondCenter.x - secondSize, secondCenter.y + secondSize);
                if (isInside(tl, thirdSize, coord)){
                    c += Square(tl, thirdSize, coord);
                    i = -1.0;}
                tr = vec2(secondCenter.x + secondSize, secondCenter.y + secondSize);
                if (isInside(tr, thirdSize, coord)){
                    c += Square(tr, thirdSize, coord);
                    i = -1.0;}
                bl = vec2(secondCenter.x - secondSize, secondCenter.y - secondSize);
                if (isInside(bl, thirdSize, coord)){
                    c += Square(bl, thirdSize, coord);
                    i = -1.0;}
                br = vec2(secondCenter.x + secondSize, secondCenter.y - secondSize);
                thirdSize = baseSize2 + addedSize2*cos(time*timeFactor2+timeStep2*i);
                if (isInside(br, thirdSize, coord)){
                    c += Square(br, thirdSize, coord);
                    i = -1.0;} 
            }
            
            bl = vec2(firstCenter.x - firstSize, firstCenter.y - firstSize);
            if (isInside(bl, secondSize, coord)){
                c += Square(bl, secondSize, coord);
                i = -1.0;}
            else{
                vec2 secondCenter = bl;
                tl = vec2(secondCenter.x - secondSize, secondCenter.y + secondSize);
                if (isInside(tl, thirdSize, coord)){
                    c += Square(tl, thirdSize, coord);
                    i = -1.0;}
                tr = vec2(secondCenter.x + secondSize, secondCenter.y + secondSize);
                if (isInside(tr, thirdSize, coord)){
                    c += Square(tr, thirdSize, coord);
                    i = -1.0;}
                bl = vec2(secondCenter.x - secondSize, secondCenter.y - secondSize);
                if (isInside(bl, thirdSize, coord)){
                    c += Square(bl, thirdSize, coord);
                    i = -1.0;}
                br = vec2(secondCenter.x + secondSize, secondCenter.y - secondSize);
                if (isInside(br, thirdSize, coord)){
                    c += Square(br, thirdSize, coord);
                    i = -1.0;} 
            }
            
            br = vec2(firstCenter.x + firstSize, firstCenter.y - firstSize);
            if (isInside(br, secondSize, coord)){
                c += Square(br, secondSize, coord);
                i = -1.0;}
            else{
                vec2 secondCenter = br;
                tl = vec2(secondCenter.x - secondSize, secondCenter.y + secondSize);
                if (isInside(tl, thirdSize, coord)){
                    c += Square(tl, thirdSize, coord);
                    i = -1.0;}
                tr = vec2(secondCenter.x + secondSize, secondCenter.y + secondSize);
                if (isInside(tr, thirdSize, coord)){
                    c += Square(tr, thirdSize, coord);
                    i = -1.0;}
                bl = vec2(secondCenter.x - secondSize, secondCenter.y - secondSize);
                if (isInside(bl, thirdSize, coord)){
                    c += Square(bl, thirdSize, coord);
                    i = -1.0;}
                br = vec2(secondCenter.x + secondSize, secondCenter.y - secondSize);
                if (isInside(br, thirdSize, coord)){
                    c += Square(br, thirdSize, coord);
                    i = -1.0;} 
            }
        }
        
        
    }
    
    glFragColor = vec4(c, c, c, 1.0);
}
