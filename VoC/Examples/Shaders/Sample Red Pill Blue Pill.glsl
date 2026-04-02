#version 420

// original https://www.shadertoy.com/view/Nsl3W8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float geo(int i, vec3 coords){
    
    if(i==0){
        vec3 pos = vec3(0.,-1,20.);
        vec3 q = abs(coords)-pos;
        return length(max(q-vec3(2.,1.,2.),1.));
    }
    
    //if(i==3) return distance(coords, vec3(sin(time)*0.7,cos(time)*0.2,sin(time)*0.2+3.))-1.;
    if(i==3) return distance(coords, vec3(sin(time+coords.z)*0.5,cos(time)*0.2,sin(time)*0.2+3.))-1.;
    if(i==2) return distance(coords, vec3(-sin(time+coords.z)*0.5,-cos(time)*0.2,sin(time)*0.2+3.))-1.;
    
    if(i==1) return distance(coords, vec3(-sin(time)*0.8,-cos(time)*0.2,sin(time)*0.2+2.44))-.4;
    float xx = cos(time*4.)*0.03+sin(coords.x)*0.1;
    float yy = sin(time*4.)*0.03;
    if(i==4) return distance(coords, vec3(-sin(time)*0.84+xx,-cos(time)*0.2+yy,sin(time)*0.2+2.24))-.2;
    
    if(i==5) return distance(coords, vec3(sin(time)*0.8,cos(time)*0.2,sin(time)*0.2+2.44))-.4;
    xx = -cos(time*4.)*0.03+sin(coords.x)*0.1;
    //xx = mod(xx,2.);
    yy = -sin(time*4.)*0.03;
    if(i==6) return distance(coords, vec3(sin(time)*0.84+xx,cos(time)*0.2+yy,sin(time)*0.2+2.24))-.2;
    
}

float sdf(vec3 coords){
    float minimum=1000.;
    for( int i = 0; i <= 5; i++){
        minimum = min(minimum,geo(i, coords));
    }
    return min(minimum,.1);
}
float march(vec3 ro, vec3 rd, int limit){
    float rlen = 0.;
    for(int i = 0; i < limit; i ++ ){
        float marchDistance = sdf(ro+(rlen*rd));
        rlen += marchDistance;
        if(marchDistance < 0.001){
            return rlen;
        }
    }
    return rlen;
}

vec3 getCol(vec3 col, vec3 coord){
    if(geo(3,coord) < 0.001){
        col.x += 2.;
        col += -cos(time)*vec3(0.3,.3,.3);
    }
    if(geo(2,coord) < 0.01){
        col *= vec3(1.0,1.0,2.);
        col += -cos(time)*vec3(0.3,.3,.3);
    }
    if(geo(0,coord) < 0.01){
        col += vec3(.01,.3,.3);
    }
    
    if(geo(1,coord) < 0.01){
        col += vec3(0.3,.3,.3);
    }
    
    if(geo(4,coord) < 0.01){
        col *= vec3(0.,.0,.8);
        col -= cos(time)*vec3(0.3,.3,.3);
    }
    
    if(geo(5,coord) < 0.01){
        col += vec3(0.3,.3,.3);
    }
    
    if(geo(6,coord) < 0.01){
        col *= vec3(0.8,.0,.0);
        col -= sin(time)*vec3(0.3,.3,.3);
    }
    return col;
}

void main(void)
{
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv =((2.*gl_FragCoord.xy)-(resolution.xy))/resolution.y;

    vec3 ro = vec3(0.,0.,1.);
    
    //point from uv image flat plane towards RayOrigin]
    //ro is just 1 unit deep in z
    vec3 rd = normalize(vec3(uv,0.)+ro);
    
    
    
    vec3 col = vec3(1.,0.,1.);// + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    float rlen = march(ro,rd, 100);
    
    col *= rlen/2.;
    col = getCol(col, ro+(rd*rlen));
    
    //dont worry be happy
    if(rlen > 3. && (ro+(rlen*rd)).y < -1.){
        col += vec3(.2,.2,.2);
        float rlen = 0.;
        bool refl = false;
        for(int i = 0; i < 100; i ++ ){
            float marchDistance = sdf(ro+(rlen*rd)*.8+vec3(0.,1.,-.2)+.1);
            rlen += marchDistance;
            if(marchDistance < 0.001){
                refl=true;
                break;
            }
        }
        if(refl){
            col = (getCol(col,ro+(rd*rlen)*.8+vec3(0.,1.,-.2)+.1)+vec3(5.))*0.09;
        }
    }
    
    // Output to screen
    glFragColor = vec4(col,0.);
}
