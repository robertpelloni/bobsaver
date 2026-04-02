// https://www.shadertoy.com/view/Xst3W7

#version 400

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

const vec2 gridSize = vec2(3.,3.);

const int arrSize = int(gridSize.x*gridSize.y);
float errAcc[int(gridSize.x*gridSize.y)];

int getIndex(vec2 p)
{
    int x = int(p.x);
    int y = int(p.y);
    if(x >= int(gridSize.x))
        return -1;
    if(y >= int(gridSize.y))
        return -1;
    if(x < 0)
        return -1;
    if(y < 0)
        return -1;
    
    return int(x+(y*int(gridSize.x)));
}

float getValue(vec2 p)
{
    int index = getIndex(p);
    if(index < 0) return 0.;
    for(int _=0;_<arrSize;_++)
        if(_==index)return errAcc[_];
    return 0.;
}
void accValue(vec2 p, float value)
{
    int index = getIndex(p);
    if(index < 0) return;
    for(int _=0;_<arrSize;_++)
        if(_==index){
            errAcc[_]+=value;
            return;
        }
}

void main()
{
    // zero-initialize :(
    for(int i = 0; i < arrSize; ++ i)
        errAcc[i] = 0.;
    
    // for performance-reasons i can't accumulate the entire image. i use a local grid.
    vec2 topLeftBound = floor(gl_FragCoord.xy/gridSize)*gridSize;

    float outpColor;
    float errCarry = 0.;
    for(float x = gridSize.x-1.; x >= 0.; --x)
    {
        for(float y = gridSize.y-1.; y >= 0.; --y)
        {
            vec2 absSamplePt = gl_FragCoord.xy - vec2(x,y);
            vec2 gridPos = absSamplePt - topLeftBound;
            if(gridPos.x < 0.) continue;
            if(gridPos.y < 0.) continue;

            vec2 uv = absSamplePt/resolution.xy;
            vec3 oc = texture(image, uv).rgb;
            float og = (oc.r+oc.g+oc.b)/3.;
            
            float err= getValue(gridPos);
            float idealColorWithErr = og + err;
            outpColor = step(0., idealColorWithErr-.5);
            err = idealColorWithErr - outpColor;

            //       *   7/16
            // 3/16 5/16 1/16
            
            //accValue(gridPos+vec2(1,0), err);
            
            //accValue(gridPos+vec2(1,0), err*.5);
            //accValue(gridPos+vec2(0,1), err*.5);

            accValue(gridPos+vec2(1,0), err*(7./16.));
            accValue(gridPos+vec2(-1,1), err*(3./16.));
            accValue(gridPos+vec2(0,1), err*(5./16.));
            accValue(gridPos+vec2(1,1), err*(1./16.));
        }
    }
    glFragColor = vec4(outpColor);
}