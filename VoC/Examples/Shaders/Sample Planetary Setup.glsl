#version 420

// original https://www.shadertoy.com/view/ltjcRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.1415972

// Sky parameters
vec3 sunDir = normalize(vec3(0.0, 1.0, 1.0));
vec3 sunCol = normalize(vec3(1.0));

vec3 shading(vec3 color, vec3 normal, vec3 rd)
{
    float t = 0.1+0.9*max(dot(sunDir, normal), 0.0);
    float spec = pow(max(0.0, dot(reflect(rd, normal), sunDir)), 128.0);
    return color*sunCol*t + sunCol*spec;
    //return color*sunCol*t + getSky(normal)*0.2;
}

float cylinderDistance(vec3 pos, vec3 o, vec3 d, float r)
{
    return length(pos-o-d*dot(pos-o,d)/dot(d,d)) - r;
}

vec4 traceCylindre(vec3 ro, vec3 rd, inout float t, vec3 o, vec3 d, float r, vec3 in_col, vec3 out_col)
{
    float h_min = 0.0;
    float h_max = length(d);
    
    float t_max = t;
    
    vec3 A = rd - d*dot(rd,d)/dot(d,d);
    vec3 B = ro - o - d*dot(ro-o,d)/dot(d,d);
    
    float delta = dot(A,B)*dot(A,B) - dot(A,A)*(dot(B,B)-r*r);
    
    if(delta<0.0)
    {
        return vec4(0.0);
    }
    
    delta = sqrt(delta);
    
    float t0 = (-dot(A,B)-delta)/dot(A,A);
    float t1 = (-dot(A,B)+delta)/dot(A,A);
    
    if(t1<0.0)
    {
        return vec4(0.0);
    }
    
    t = t0>0.0?t0:t1;
    
    vec3 pos = ro+rd*t;
    
    float opp = sign(cylinderDistance(ro, o, d, r));
    float h = dot(d,pos-o)/length(d);
    if(h<h_min)
    {
        t = t1;
        pos = ro+rd*t;
        h = dot(d,pos-o)/length(d);
        opp *= -1.0;
        if(h<h_min)
        {
            t = t_max;
            return vec4(0.0);
        }
    }

    if(h>h_max)
    {
        t = t1;
        pos = ro+rd*t;
        h = dot(d,pos-o)/length(d);
        opp *= -1.0;
        if(h>h_max || h<h_min)
        {
            t = t_max;
            return vec4(0.0);
        }
    }
    
    if(t > t_max)
    {
            t = t_max;
            return vec4(0.0);
    }
    
    
    vec3 norm = -normalize(cross(d, cross(d, pos-o)));
    norm *= opp;
    
    //vec3 col = mix(in_col, out_col, 0.5+0.5*opp);
        
    //col *= max(0.0, dot(norm, sunDir));
    
    vec3 col = shading(out_col, norm, rd);
    
    return vec4(col, 1.0);
}

float coneDistance(vec3 pos, vec3 o, vec3 d, float r)
{
    return length(pos-o-d*dot(pos-o,d)) - abs(dot(pos-o,d))*r;
}

vec4 traceCone(vec3 ro, vec3 rd, inout float t, vec3 o, vec3 d, float h_max, float r, vec3 col)
{
    float t_max = t;
    
    //--------------------------------------
    // polynome terms computation
    // 
    
    // cylindrical part
    vec3 A = rd - d*dot(rd,d);
    vec3 B = ro - o - d*dot(ro-o,d);
    
    // conical part
    vec3 A_ = d*dot(rd,d);
    vec3 B_ = d*dot(ro-o,d);
    
    float a = dot(A,A) - r*r*dot(A_, A_);
    float b = dot(A,B) - r*r*dot(A_, B_);
    float c = dot(B,B) - r*r*dot(B_, B_);
    
    float delta = b*b-a*c;
    
    if(delta<0.0)
    {
        return vec4(0.0);
    }
    
    
    delta = sqrt(delta);
    
    float t0 = (-b-delta)/a;
    float t1 = (-b+delta)/a;
    
    // warning: 'a' can be negative, we therefore need extra precaution (compared to the cynlindrical case)
    float tt0 = min(t0, t1);
    float tt1 = max(t0, t1);
    
    if(tt1 < 0.0)
        return vec4(0.0);
    
    t = tt0>0.0?tt0:tt1; // we retain the smallest positive value
        
    vec3 pos = ro+rd*t;
    
    // this parameter is -1 if ro lies inside the cone and 1 else
    // -- it is used for inverting inside normals in the former case
    float opp = sign(coneDistance(ro,o,d,r));
    
    //--------------------------------
    // height tests
    
    float h = dot(d,pos-o);
    float h_min = 0.0;
    if(h<h_min)
    {
        // only possible if t == tt0
        t = tt1;
        pos = ro+rd*t;
        h = dot(d,pos-o);
        opp *= -1.0;
        if(h<h_min)
        {
            t = t_max;
            return vec4(0.0);
        }
    }

    if(h>h_max)
    {
        // only possible if t == tt0
        t = tt1;
        pos = ro+rd*t;
        h = dot(d,pos-o);
        opp *= -1.0;
        if(h>h_max || h<h_min)
        {
            t = t_max;
            return vec4(0.0);
        }
    }
    
    if(t>t_max)
    {
        t = t_max;
        return vec4(0.0);
    }
    
    vec3 norm = -normalize(cross(pos-o, cross(d, pos-o)));
    norm *= sign(dot(d, pos-o));
    norm *= opp;
    
        
    col = shading(col, norm, rd);
    
    return vec4(col, 1.0);
}

vec4 traceCap(vec3 ro, vec3 rd, inout float t, vec3 c, vec3 n, float rad, vec3 col)
{
    float t_max = t;
    
    t = dot(c-ro, n)/dot(rd,n);
    if(t<0.0 || t > t_max)
    {
        t = t_max;
        return vec4(0.0);
    }
    
    vec3 p_proj = ro+rd*t;
    
    if(length(c-p_proj) > rad)
    {
        t = t_max;
        return vec4(0.0);
    }
    
    col = shading(col, n, rd);
    
    return vec4(col, 1.0);
}

vec4 traceCapedCone(vec3 ro, vec3 rd, inout float t, vec3 o, vec3 d, float h_max, float r, vec3 in_col)
{
    vec4 res = traceCone(ro, rd, t, o, d/length(d), h_max, r, in_col);
    vec4 col = vec4(0.0);
    col = res;
    
    res = traceCap(ro, rd, t, o+normalize(d)*h_max, normalize(d), r*h_max, in_col) ;
    col = vec4(col.rgb*(1.0-res.a)+res.rgb*res.a, max(res.a, col.a));
                
    return col;
}

vec4 traceSphere(vec3 ro, vec3 rd, inout float t, vec3 o, float r, vec3 col)
{
    float t_max = t;
    float delta = pow(dot(rd, ro) - dot(o,rd), 2.0) - (dot(o, o)+dot(ro,ro)-2.*dot(o, ro)-r*r);
    
    if(delta < 0.0)
        return vec4(0.0);
    
    delta = sqrt(delta);
    float t1 = dot(o, rd) - dot(rd, ro) - delta;
    float t2 = t1 + 2.0*delta;
    
    t = t1 > 0.0 ? t1 : t2;
    
    if(t > t_max || t < 0.0)
    {
        t = t_max;
        return vec4(0.0);
    }
    
    vec3 p = ro + t*rd;
    vec3 n=normalize(p-o);
    
    col = shading(col, n, rd);
    
    return vec4(col, 1.0);
}

vec4 tracePlane(vec3 ro, vec3 rd, inout float t, vec3 o, vec3 n, vec3 col)
{
    float t_max = t;
    
    t = -dot(ro, n)/dot(rd,n);
    if(t<0. || t>t_max)
    {
        t = t_max;
        return vec4(0.0);
    }
    
    col = shading(col, n, rd);
    
    return vec4(col, 1.0);
}

vec4 traceArrow(in vec3 ro, in vec3 rd, inout float t, vec3 base, vec3 top, float r, vec3 col)
{    
    vec4 tempCol = traceCapedCone(ro, rd, t, top, base-top, 2.0*length(top-base)*0.2, 0.5*r/length(top-base)*5., col);
    vec4 col_ = tempCol;
    tempCol = traceCylindre(ro, rd, t, base, 3.0*(top-base)*0.2, 0.5*r, col, col);
    col_ = mix(col_, tempCol, tempCol.w);
    
    return col_;
}

vec4 traceFrame(in vec3 ro, in vec3 rd, inout float t, in mat4 m)
{
    vec4 col = vec4(0.0);
    float t0 = t;
    
    float r = (length(m[0])+length(m[1])+length(m[2]))/3./5.0;
    
    vec4 tempCol;
    
    tempCol = traceSphere(ro, rd, t, m[3].xyz, r, vec3(1.0));
    col = tempCol;

    /*
    tempCol = traceCapedCone(ro, rd, t, m[3].xyz + m[0].xyz, -m[0].xyz*0.2, 2.0*length(m[0].xyz)*0.2, 0.5*r/length(m[0])*5., vec3(1.0, 0.0, 0.0));
    col = mix(col, tempCol, tempCol.w);
    tempCol = traceCylindre(ro, rd, t, m[3].xyz, 3.0*m[0].xyz*0.2, 0.5*r, vec3(1.0, 0.0, 0.0), vec3(1.0, 0.0, 0.0));
    col = mix(col, tempCol, tempCol.w);
    
    tempCol = traceCapedCone(ro, rd, t, m[3].xyz + m[1].xyz, -m[1].xyz*0.2, 2.0*length(m[1].xyz)*0.2, 0.5*r/length(m[1])*5., vec3(0.0, 1.0, 0.0));
    col = mix(col, tempCol, tempCol.w);
    tempCol = traceCylindre(ro, rd, t, m[3].xyz, 3.0*m[1].xyz*0.2, 0.5*r, vec3(0.0, 1.0, 0.0), vec3(0.0, 1.0, 0.0));
    col = mix(col, tempCol, tempCol.w);
    
    tempCol = traceCapedCone(ro, rd, t, m[3].xyz + m[2].xyz, -m[2].xyz*0.2, 2.0*length(m[2].xyz)*0.2, 0.5*r/length(m[2])*5., vec3(0.0, 0.0, 1.0));
    col = mix(col, tempCol, tempCol.w);
    tempCol = traceCylindre(ro, rd, t, m[3].xyz, 3.0*m[2].xyz*0.2, 0.5*r, vec3(0.0, 0.0, 1.0), vec3(0.0, 0.0, 1.0));
    col = mix(col, tempCol, tempCol.w);
    */
    
    tempCol = traceArrow(ro, rd, t, m[3].xyz, m[3].xyz+m[0].xyz, r, vec3(1.0, 0.0, 0.0));
    col = mix(col, tempCol, tempCol.w);
    
    tempCol = traceArrow(ro, rd, t, m[3].xyz, m[3].xyz+m[1].xyz, r, vec3(0.0, 1.0, 0.0));
    col = mix(col, tempCol, tempCol.w);
    
    tempCol = traceArrow(ro, rd, t, m[3].xyz, m[3].xyz+m[2].xyz, r, vec3(0.0, 0.0, 1.0));
    col = mix(col, tempCol, tempCol.w);
    
    return col;
}

mat4 Identity()
{
    mat4 m;
    m[0] = vec4(1.0, 0.0, 0.0, 0.0);
    m[1] = vec4(0.0, 1.0, 0.0, 0.0);
    m[2] = vec4(0.0, 0.0, 1.0, 0.0);
    m[3] = vec4(0.0, 0.0, 0.0, 1.0);
    
    return m;
}

mat4 Rotation(vec3 axisAngle)
{
    float alpha = length   (axisAngle);
    vec3  axis  = normalize(axisAngle);
    
    float c = cos(alpha);
    float s = sin(alpha);
    float t = 1.0-c;
    float x = axis.x;
    float y = axis.y;
    float z = axis.z;
    
    mat4 m;
    m[0] = vec4(t*x*x + c,   t*x*y + z*s, t*x*z - y*s, 0.0);
    m[1] = vec4(t*x*y - z*s, t*y*y + c  , t*y*z + x*s, 0.0);
    m[2] = vec4(t*x*z + y*s, t*y*z - x*s, t*z*z + c  , 0.0);
    m[3] = vec4(0.0, 0.0, 0.0, 1.0);
    // Note : see here http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToMatrix/index.htm
    
    return m;
}

mat4 Translation(vec3 d)
{
    mat4 m;
    m[0] = vec4(1.0, 0.0, 0.0, 0.0);
    m[1] = vec4(0.0, 1.0, 0.0, 0.0);
    m[2] = vec4(0.0, 0.0, 1.0, 0.0);
    m[3] = vec4(d, 1.0);
    
    return m;
}

mat4 Scale(float factor)
{
    mat4 m;
    m[0] = vec4(factor, 0.0, 0.0, 0.0);
    m[1] = vec4(0.0, factor, 0.0, 0.0);
    m[2] = vec4(0.0, 0.0, factor, 0.0);
    m[3] = vec4(0.0, 0.0, 0.0, 1.0);
    
    return m;
}

mat4 GPS(float latitude, float longitude)
{
    vec3 north = vec3(-sin(latitude)*cos(longitude), cos(latitude), sin(latitude)*sin(longitude));
    vec3 up    = vec3(cos(latitude)*cos(longitude),sin(latitude),cos(latitude)*sin(-longitude));
    vec3 east  = vec3(-sin(longitude),0.,-cos(longitude));

    
    mat4 m;
    m[0] = vec4(north, 0.0);
    m[1] = vec4(up, 0.0);
    m[2] = vec4(east, 0.0);
    m[3] = vec4(up, 1.0);
    
    return m;
}

vec3 render( in vec3 ro, in vec3 rd)
{
    vec3 col = vec3(0.0);
    //vec3 col = getSky(rd);
    
    float t = 100.0;
    vec4 res; 
    
    mat4 I = Identity();
    mat4 R = Rotation(vec3(time*2.));
    mat4 T = Translation(1.0*vec3(cos(time*2.), 0., sin(time*2.)));
    mat4 S = Scale(1.0+cos(time*3.)*0.5);
    
    mat4 m;
    
    m = I;
    res = traceFrame(ro, rd, t, m) ;
    col = col*(1.0-res.a)+res.rgb*res.a;
    
    mat4 T_rotation  = Translation(3.0*vec3(cos(time), 0., sin(time)));
    mat4 R_obliquity = Rotation(vec3(0.0, 0.0, 23.*M_PI/180.));
    mat4 R_time      = Rotation(vec3(0.0, time*5., 0.0));
    m = T_rotation*R_obliquity*R_time*Scale(0.5);
    res = traceFrame(ro, rd, t, m) ;
    col = col*(1.0-res.a)+res.rgb*res.a;
    
    m = T_rotation*R_obliquity*R_time*Scale(0.5)*GPS(M_PI/4., 0.)*Scale(0.5);
    res = traceFrame(ro, rd, t, m) ;
    col = col*(1.0-res.a)+res.rgb*res.a;
    
    vec3 lightDir = normalize(-m[3].xyz);
    float lightDirX = dot(lightDir, m[0].xyz)/length(m[0].xyz);
    float lightDirY = dot(lightDir, m[1].xyz)/length(m[1].xyz);
    float lightDirZ = dot(lightDir, m[2].xyz)/length(m[2].xyz);
    float altitude  = acos(lightDirY);
    float azimut    = atan(lightDirZ, lightDirX);
    lightDir = vec3(sin(altitude)*cos(azimut), cos(altitude), sin(altitude)*sin(azimut));
    lightDir = (m * vec4(lightDir, 0)).xyz * 4.;
    res = traceArrow(ro, rd, t, m[3].xyz, m[3].xyz+.5*lightDir, 0.1, vec3(1.0, 1.0, 0.0));
    col = mix(col, res.rgb, res.a);
    
    res = traceSphere(ro, rd, t, 3.0*vec3(cos(time), 0., sin(time)), .5, vec3(0.5, 0.5, 1.0)) ;
    col = col*(1.0-res.a*0.3)+res.rgb*res.a*0.3;
    
    
    
    return  col;
}

vec3 postEffects(vec3 col, vec2 uv)
{
    // Gamma correction
    col = pow(col, vec3(0.45));
    
    return col;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/ resolution.y;

    vec2 m = mouse*resolution.xy.xy/resolution.xy;
    
    float speed = 0.0;
    
    // camera & ray
    float phi = m.x * M_PI * 2.0;
    //if(mouse*resolution.xy.x < 0.5)
    //    phi=time*M_PI*0.1;
    
    float psi = m.y * M_PI;
    //if(mouse*resolution.xy.y < 0.5)
    //    psi = 0.33*M_PI;
    vec3 ro = 5.0*vec3(cos(phi)*sin(psi), cos(psi), sin(phi)*sin(psi));
    vec3 ta = vec3(0.0);
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 rd = ca * normalize( vec3(p.xy,1.5));
    
    
    vec3 col = render( ro, rd);
    
    col = postEffects(col, gl_FragCoord.xy/resolution.xy);
    
    glFragColor = vec4(col, 1.0);
}
