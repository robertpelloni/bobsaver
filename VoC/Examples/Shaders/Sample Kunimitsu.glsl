#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WdByWy

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/// kunimitsu

/// high quality version
// #define CONFIG_HQ

/// simple antyaliasing using loop in shader.
// #define CONFIG_AA 8.0

/// camera
// #define STATIC_CAMERA2
// #define STATIC_CAMERA4

///
/// Framework
///

#ifdef CONFIG_HQ
    #define E 0.0001
#else
    #define E 0.0002
#endif
#define INF 1e20
#define SKY_DIST 20.0

vec2 rot( vec2 p, float l){
    float c= cos(l), s= sin(l);
    return vec2(
        c*p.x - s*p.y,
        s*p.x + c*p.y
    );
}

float smin( float a, float b, float k ){ /// default k = 32.0
    return 125.0 <= max(abs(k*a),abs(k*b)) ? min(a,b) : -log2( exp2( -k*a ) + exp2( -k*b ) )/k;
}

float smax( float a, float b, float k ){ /// default k = 32.0
    return -smin( -a, -b, k );
}

/// rand 2d
float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

/// classic noise 2d
float noise2d(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);

    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}

/// classic noise 3d
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = permute(b.xyxy);
    vec4 k2 = permute(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = permute(c);
    vec4 k4 = permute(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

/// FBM (perlin noise) 2D
///@warning require noise
///@return from 0.0 to 1.0 (but values above 0.8 are rere)
#define FBM_NUM_OCTAVES 5
float fbm(vec2 x) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < FBM_NUM_OCTAVES; ++i) {
        v += a * noise2d(x);
        x = rot * x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

/// FBM (perlin noise) 2D
/// return value from 0.0 to 1.0
///@warning require noise
///@return from 0.0 to 1.0
float fbm(vec3 x) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100);
    for (int i = 0; i < FBM_NUM_OCTAVES; ++i) {
        v += a * noise(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

/// arch
float dfArch( vec3 ph, float rad, float rad2 ){
    return length( vec3(
        abs( length( vec2(max( 0.0, ph.x ),ph.z+rad) )-rad )
        ,
        ph.y
        ,
        max( 0.0, -ph.x )
    )) - rad2;
}

/// kind of cyliunder, but will balls at ends
float dfCapsule(vec3 p, float radius, float h ){
    p.z= abs(p.z) - h;
    return ( 0.0 < p.z ) ? length(p) - radius : length(p.xy) - radius;
}

///@param l should be between -0.5*3.14 and 0.5*3.14
float dfConeAndBall(vec3 p, float l, float radius ){
    vec2 ph1= vec2( length(p.xy), p.z );
    vec2 ph= rot( ph1, l );
    if( 0.0 < ph.y ){
        return length(ph) - radius;
    }else{
        float c= -radius / cos( 0.5*3.141592653589 - l );
        if( 0. < l && ph1.y < c ){
            return length( ph1-vec2(0,c) );
        }else{
            return ph.x - radius;
        }
        return ph.x - radius;
    }
    return INF;
}

///
/// Scene
///
vec3 localP;

vec3 getWatermelonColor( vec3 p, bool forBra ){
    vec3 ph= normalize( p );
    float l= atan( ph.x, ph.z );
    float b= atan( length(ph.xz), ph.y );
    const float mo= 0.1 * 3.141592653589;
    float h= mod( l, mo ) - mo / 2.0;
    float h2= floor( l / (mo*0.5) );
    if( abs(h) < 0.04 * 3.141592653589 * fbm(vec2(b*20.0,h2)) || fbm(ph*15.0) < 0.28 )
    {
        return vec3( .2, .15, .1 );
    }
    if( forBra ){
        return vec3(.2,.6,.2);
    }
    return mix( vec3(.2,.6,.2), vec3(.12,.4,.1), fbm(ph*9.0) );
}

float mapBra(vec3 p){
    float r= INF;
    float rc;
    vec3 ph;

    /// boobs
    const float s= 128.0;
    const vec3 pm= vec3(0,0.007,0.004);
    {
        ph= p - pm;
        ph.x= abs(ph.x)-0.18;
        ph.y += 0.88;
        ph.z -= 0.16;
        localP= ph;
        rc= length(ph)-0.22;

        ph.y -= 0.15;
        ph.xy= rot( ph.xy, 0.3*3.141592653589 );
        rc= smax( rc, smax(-ph.x,ph.y, s), s );
        r= min( r, rc );

        ph= p - pm;
        ph.y += 0.97;
        ph.z -= 0.25;
        ph.yz= rot( ph.yz, -0.5 );
        r= smax( r, -ph.y, s );

        /// niples
        ph= p;
        ph.x= abs(ph.x) - 0.19;
        ph.y += 0.90;
        ph.z -= 0.375;
        r= smin( r, length(ph)-0.01, 256.0 );
    }

    /// boobs connector
    {
        ph= p - pm + vec3(0,0.007,0.0017);
        ph.y += 0.97;
        ph.z -= 0.320;
        const float rad= 0.5;
        ph.x= abs(ph.x);

        ph.yz -= 0.003*vec2(1,-1);

        ph.yz= rot( ph.yz, -0.5 );

        ph.z -= rad;
        ph.xz= rot( ph.xz, 1.38 );
        rc= length( vec3( ph.y, length(vec2(ph.x,min(ph.z,0.0)))-rad, max(ph.z,0.0) ) )-0.003;
        r= smin( r, rc, 350.0 );
    }

    /// bra side straps
    {
        /// point of connection with boob part of bra
        ph= p;
        ph.x= abs(ph.x)-0.33;
        ph.y += 0.95;
        ph.z -= 0.28;

        /// rotations
        ph.yz= rot( ph.yz, -0.25 );
        ph.xz= rot( ph.xz, 0.8 );
        
        /// make an arch
        const float rad= 0.34;
        const float rad2= 0.003;
        r= smin( r, dfArch(ph, rad, rad2), 128.0 );
    }

    /// bra top straps
    {
        /// point of connection with boob part of bra
        ph= p;
        ph.x= abs(ph.x)-0.17;
        ph.y += 0.75;
        ph.z -= 0.33;

        /// rotations
        ph.yz= rot( ph.yz, 0.50 );
        ph.xy= rot( ph.xy, 0.15 );
        
        /// make an arch with extension
        const float rad= 0.34;
        const float len= 0.39;
        ph.y -= len;
        ph.z += rad;
        rc= length( vec3(
            abs( length( vec2(max( 0.0, ph.y ),ph.z) )-rad )
            ,
            ph.x
            ,
            max( 0.0, -len-ph.y )
        )) - 0.003;
        r= smin( r, rc, 256.0 );
    }

    return r;
}

float mapWatermelons(vec3 p){
    p.x += 0.4;
    p.y -= 1.0;

    vec3 ph= p;
    ph.xy= mod( ph.xy-8.0, 2.0 ) - 1.0;
    vec2 sr= floor( p.xy / 2.0 );
    const float s= 0.8;
    sr += .0;
    ph.x += s*(0.5 - rand( sr ));
    ph.y += s*(0.5 - rand( sr+vec2(.1) ));

    ph.z += .1;
    localP= ph;

    ///@todo that should be done after raytracing, during color calculation, but here we already have sr
    localP.xy= rot( localP.xy, rand( sr+.3 )*6.0 );
    localP.yz= rot( localP.yz, rand( sr+.2 )*6.0 );
    
    float r= length(ph) - 0.25 - 0.1 * rand( sr+.4);
    r= min( r, max( 0.2, p.z ) );
    return r;
}

/// cat mask
float mapMask(vec3 p){
    p.x= abs(p.x);
    p.z -= 0.1;
    vec3 ph= p;
    float r, rc, h;

    /// forehead
    r= length(p-vec3(.0,.3,.0))-.3;

    /// lips up
    rc= dfConeAndBall( p - vec3(0,0,.2), -0.2*3.14, 0.15 );
    ph= p;
    ph.yz= rot( ph.yz, 0.3 * 3.1415 );
    rc= smax( rc, ph.z - .2, 32.0 );
    ph= p;
    rc= smax( rc, -p.y-0.15, 32.0 );
    r= smin( r, rc, 32.0 );

    /// lips down
    rc= dfConeAndBall( p - vec3(0,-.15,.20), -0.27*3.14, 0.07 );
    ph = p;
    ph.yz= rot( ph.yz, 0.1 * 3.1415 );
    rc= smax( rc, -ph.y-.25, 32.0 );
    r= smin( r, rc, 500.0 );

    /// cat sides
    ph= p;
    ph.xy= rot( ph.xy, 0.1 * 3.14 );
    r= smax( r, ph.x - 0.25, 32.0 );
    ph= p;
    ph.xy= rot( ph.xy, 0.2 * 3.14 );
    r= smax( r, ph.x - 0.25, 32.0 );

    /// ears
    ph= p;
    ph.x -= 0.25;
    ph.y -= 0.65;
    ph.z -= 0.08;
    ph.xy= rot( ph.xy, 0.15 * 3.14 );
    rc= dfConeAndBall( ph.xzy, -0.1*3.14, 0.04 );
    rc= smax( rc, ph.z-0.05, 200.0 );
    rc= max( rc, 0.4-p.y );
    r= smin( r, rc, 256.0 );

    /// cat bottom
    r= smax( r, -p.z, 128.0);

    /// done
    return r;
}

float mapHair(vec3 p){
    float r= length(p.xy-vec2(0,.27) )-0.26;

    vec3 ph= p;
    ph.yz= rot( ph.yz, 0.02 );
    ph.xy= mod( ph.xy, 0.01 ) - 0.005;
    r= max( r, 0.003-length(ph.xy) );

    ph= p;
    ph.yz= rot( ph.yz, -0.03 );
    ph.xy= mod( ph.xy, 0.014 ) - 0.007;
    r= max( r, 0.002-length(ph.xy) );

    ph= p;
    ph.xy= mod( ph.xy, 0.004 ) - 0.002;
    r= max( r, 0.001-length(ph.xy) );

    r= max( r, p.z-0.12 );
    r= max( r, 0.3-0.18-p.y);
    return r;
}

/// map of body
float mapBody(vec3 p){
    float r=INF, rc;
    vec3 ph= p;

    /// neck
    ph= p- vec3(0,-.3, -.03);
    r= dfCapsule(ph.xzy, 0.13, 0.3 );

    /// head
    ph= p- vec3(0,+.18, .01);
    rc= dfCapsule(ph.xzy, 0.19, 0.1 );
    r= smin( r, rc, 128.0 );

    /// jaws
    {
        ph= p;
        ph.y -= 0.03;
        ph.z -= 0.12;

        ph.x= abs(ph.x) - 0.055;
        ph.xz= rot( ph.xz, -0.6 );

        ph.x = max( 0.0, abs(ph.x)-0.03 );
        ph.y = max( 0.0, abs(ph.y)-0.1 );
        ph.z = max( 0.0, abs(ph.z)-0.05 );

        rc= length(ph)-0.08;
        r= smin( r, rc, 64.0 );
    }

    /// ears
    {
        ph= p;
        ph.x= abs(ph.x) - 0.195;

        ph.y -= 0.11;
        ph.z -= 0.05;
        vec3 ph2= ph;

        ph.yz= rot( ph.yz, 0.7 );
        ph.xz= rot( ph.xz, -0.3 );

        ph.y= max( 0.0, abs(ph.y)-0.01 );
        ph.z= max( 0.0, abs(ph.z)-0.02 );

        rc= length(ph)-0.018;

        ph2.y += 0.001;
        ph2.z += 0.008;
        rc= smax( rc, -(length(ph2.yz)-0.009), 128.0 );

        ph2.x -= 0.010;
        ph2.y += 0.017;
        rc= smin( rc, length(ph2)-0.01, 2048.0 );

        r= smin( r, rc, 512.0 );
    }

    /// upper body
    {
        ph= p;
        float rad= 1.6;

        /// mirror & extend X
        ph.x= max( 0.0, abs(ph.x)-0.2 );
        ph.y += 0.98;
        ph.z -= 0.00;

        /// rotate YZ
        ph.z += rad;
        ph.yz= rot( ph.yz, 0.1*3.1415 );
        ph.z -= rad;
        
        /// without bones
        if( ph.y < 0.0 ){
            rc= length( vec2( length( ph.yz + vec2(0,rad) ) - rad, ph.x ) ) - 0.2;
        }else{
            rc= length(ph)-0.2;
        }

        r= smin( r, rc, 32.0 );
    }

    /// ribs side shape cut
    for(float py=0.0;py<6.0;py+=1.0){
        ph= p;
        ph.z += (3.0 < py ? 0.11 : 0.2);
        float h= 0.1;
        
        float hy= ph.y - (py-14.0)*h;

        h= 3.0 < py ? 0.4 : 0.5;
        h= abs( length( vec2( ph.x, ph.z ) )-h );

        rc= length( vec2( hy, h ) )-0.01;

        r= smax( r, -rc, 32.0 );
    }

    /// ribs bottom cut
    {
        ph= p;
        ph.y += 1.1;
        
        ph.z -= 0.10;

        ph.xy= rot( ph.xy, -0.25*3.141592653589 );
        rc= smax( ph.x, ph.y, 32.0 );

        r= smax( r, -rc, 32.0 );
    }

    /// belly
    {
        ph= p;
        float rad= 2.8;
        
        ph.x= max( 0.0, abs(ph.x)-0.14 );
        ph.y += 1.1;
        ph.z += 0.15;

        ph.z += rad;
        ph.z -= rad;

        if( 0.0 > ph.y ){
            rc= length( vec2( length( ph.yz + vec2(0,rad) ) - rad, ph.x ) ) - 0.3;
        }else{
            rc= length(ph)-0.3;
        }
        r= smin( r, rc, 32.0 );
    }

    /// abs
    for(float sx=-1.0;sx<2.0;sx+=2.0)
    for(float py=0.0;py<3.0;py+=1.0){
        ph= p;
        
        ph.y += 1.3;
        ph.yz= rot( ph.yz, -0.15 );

        ph.x += sx*0.08;
        ph.y += py*0.165;

        ph.z -= 0.08;

        rc= length( ph )-0.03;

        r= smin( r, rc, 32.0 );
    }

    /// navel (pempek in pl)
    {
        ph= p;
        ph.y += 1.57;
        ph.z -= 0.13;
        rc= length( ph ) - 0.005;
        r= smax( r, -rc, 180.0 );
    }

    /// hands
    {
        ph= p;
        ph.x= abs(ph.x);
        ph.xy += vec2( -.4, .4 );
        ph.xy= rot( ph.xy, -0.23*3.14 );
        ph.yz= rot( ph.yz, -0.035*3.14 );
        ph.y += 2.0;
        rc= dfCapsule(ph.xzy, 0.12, 2.0 );

        /// arm
        ph.y -= 2.0;
        rc= smin( rc, length(ph)-0.08, 32.0 );

        /// albow
        ph.y += 0.7;
        rc= smin( rc, length(ph)-0.08, 32.0 );

        /// biceps
        ph.y -= 0.5;
        ph.z += 0.10;
        rc= smin( rc, dfArch( ph.zxy, 0.17, 0.03 ), 32.0 );

        /// apply
        r= smin( r, rc, 32.0 );
    }

    /// boobs
    {
        #ifdef CONFIG_HQ
        for(float s=-1.0;s<2.0;s+=2.0)
        #endif
        {
            ph= p;
            #ifndef CONFIG_HQ
            ph.x= abs(ph.x);
            const float s= 1.0;
            #endif
            ph.x= (ph.x)*s-0.18;
            ph.y += 0.75;
            ph.z -= 0.05;
            ph.yz= rot( ph.yz, -0.8 );
            rc= dfCapsule(ph, 0.2, 0.18);
            r= smin( r, rc, 32.0 );
        }
    }

    /// pectoralis muscle
    {
        ph= p;
        ph.x= abs(ph.x);
        ph.x -= 0.35;
        ph.y += 0.55;
        ph.z -= 0.08;
        ph.xy= rot( ph.xy, -1.1 );
        ph.xz= rot( ph.xz, 0.3 );
        rc= dfCapsule(ph.zyx, 0.02, 0.2);
        r= smin( r, rc, 32.0 );
    }

    /// done
    return r;
}

float mapNeckles(vec3 p){
    p.y += 0.21;
    p.y= abs(p.y);
    p.y= max( 0.0, p.y-0.02 );
    p.z += 0.04;
    float r= length(vec2(p.y,length(p.xz)-0.14)) - 0.01;
    return r;
}

int lastMatId= 0;
float map(vec3 p){
    float r=INF, rc;
    vec3 ph= p;
    lastMatId= 0;
    vec3 localLocalP;

    /// cat mask
    rc= mapMask(p);
    if( rc < r ){
        lastMatId= 1;
        r= rc;
        localLocalP= localP; ///@todo that can be delete, unless I change something later on, in case I will leave it for now.
    }

    /// body
    rc= mapBody(p);
    if( rc < r ){
        lastMatId= 2;
        r= rc;
        localLocalP= localP; ///@todo that can be delete, unless I change something later on, in case I will leave it for now.
    }

    /// hair
    rc= mapHair(p);
    if( rc < r ){
        lastMatId= 3;
        r= rc;
        localLocalP= localP; ///@todo that can be delete, unless I change something later on, in case I will leave it for now.
    }

    /// bra
    rc= mapBra(p);
    if( rc < r ){
        lastMatId= 4;
        r= rc;
        localLocalP= localP;
    }

    /// watermelons
    rc= mapWatermelons(p);
    if( rc < r ){
        lastMatId= 5;
        r= rc;
        localLocalP= localP;
    }

    /// necklace
    rc= mapNeckles(p);
    if( rc < r ){
        lastMatId= 6;
        r= rc;
        localLocalP= localP; ///@todo that can be delete, unless I change something later on, in case I will leave it for now.
    }

    /// done
    localP= localLocalP;
    return r;
}

///
/// Rendering
///

float shadow( in vec3 ro, in vec3 rd, float mint, float maxt )
{
    const float k= 32.0;
    float r= 1.0;
    float ph = INF;
    for( float t=mint; t < maxt; )
    {
        float h = map(ro + rd*t);
        if( h<E )
            return 0.0;
        
        float d, y;
        {
            float r1= max( h, ph );
            float r2= min( h, ph );
            y= r2*r2 / (2.0 * r1);
            d= sqrt( r2*r2 - y*y );
        }

        r= min( r, k * h / t ); /// faster
        // r= min( r, k * d / max(E,t-y) ); /// better
        t += h;
    }
    r= clamp(r,0.0,1.0);
    return r;
}

vec3 render( vec3 sp, vec3 dir, out vec3 p ){
    float dis= 0.0;
    p= sp;
    float t= 0.0;
    for( int a=0;a<0x100;a++){
        t += dis;
        p = sp + dir*t;
        dis= map(p);
        if( dis < E ){
            break;
        }
    }

    if( t < SKY_DIST )
    {
        vec3 localLocalP= localP;
        int matId= lastMatId;

        /// normal vector (usual way)
          //vec3 nor= vec3( 0 );
        //for( int i=min( frames, 0 ); i<4; i++){
        //    vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        //    nor += e * map( p + e*E );
        //}
        //nor= normalize( nor );

        /// corner shadow (usual way)
        //float cs= 1.0;
        //for( float a=0.001+float(min(0,frames)); a<0.02; a*=2.0 )cs= min( cs, map( p + nor * a ) / a );
        //cs= clamp( cs, 0.0, 1.0 );
        
        /// normal vector & corner shadow in single loop
        ///@warning black magic
        vec3 nor= vec3( 0 );
        float cs= 1.0;
        for( int i=min( frames, 0 ); i<10; i++){
            vec3 mapArg;
            vec3 e;
            float a;
            if( i < 4 ){
                e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
                mapArg= p + e*E;
            }else{
                nor= normalize( nor );
                a= 0.001 * pow( 2.0, float(i-4) );
                mapArg= p + nor * a;
            }

            float mapResult= map( mapArg );

            if( i < 4 ){
                nor += e * mapResult;
            }else{
                cs= min( cs, mapResult / a );
            }
        }
        cs= clamp( cs, 0.0, 1.0 );
        

        const vec3 sunDir= normalize( vec3( .9, .7, 0.5 ) );
        const vec3 sunDir2= normalize( vec3( .1, .1, .9 ) );

        /// shadow
        float sh= dot(nor,sunDir);
        sh= clamp( sh, 0.0, 1.0 );
        if( 0.0 < sh ){
            sh *= shadow( p, sunDir, 0.001, 5.0 );
        }
        sh= clamp( sh, 0.0, 1.0 );

        /// base color
        vec3 baseColor= vec3(1);
        switch(matId){
            case 0: /// water
                baseColor= vec3(.3,.3,.9);
                break;
            case 1: /// mask
            {
                baseColor= vec3(1);

                vec3 ph= p;
                ph.x= abs(ph.x);

                /// ears
                if( true
                    && 0.51 < rot(ph.xy,0.72).y
                    && -0.23 < rot(ph.xy,2.3).y
                    && -0.14 < rot(ph.xy,4.89).y
                )
                    baseColor= vec3(.9,.9,.7);

                /// eyes & nose & mustache
                vec2 em= vec2(.02,.24); /// eyes move
                vec3 ph2= ph; /// mustache position
                ph2.z -= 0.2;
                ph2.xz= rot( ph2.xz, -0.25* 3.141592653589 );
                ph2.yz= rot( ph2.yz, -0.3 );
                ph2.y= abs(abs(ph2.y)-0.02)-0.02;
                ph2.z= max( 0.0, abs(ph2.z+0.07)-0.03 );
                if( true
                    /// eyes
                    && length(ph.xy-em) < 0.16
                    && length(ph.xy-em-vec2(1,-1)*vec2(.28)) < 0.26
                    /// nose
                    || smin(
                        length(ph.xy-vec2(0,-.05)) - 0.035
                        ,
                        length(ph.xy-vec2(0,-.08)) - 0.015
                        , 256.0
                    ) < 0.0
                    /// mustache
                    || length( ph2.yz ) < 0.01
                )
                    baseColor= vec3(.5);

                /// lips & sign
                /// sign
                ph2= ph; 
                ph2.y -= 0.18;
                ph2.xy= vec2( min(ph2.x,ph2.y), max(ph2.x,ph2.y) );
                /// lips position
                ph.y += 0.03;
                ph.yz= rot( ph.yz, -0.25 );
                ph.z -= 0.25;
                if( 
                    /// lips
                    abs(ph.y) < 0.02
                        && 0.0 < ph.z
                    || length(ph.yz-vec2(-0.01,0)) < 0.03
                    /// sign on top
                    || abs(ph2.x-0.02) < 0.01
                        && (ph2.y) < 0.07
                ){
                    baseColor= vec3(.9,.45,.45);
                }
                break;
            }
            case 2: /// body

                baseColor= vec3(229,197,149) / 256.;

                /// moles
                {
                    vec3 ph= 100.0 * p;
                    vec2 sr= floor( ph.xy / 2.0 ) + 12.0 * vec2(floor( ph.z / 2.0 ));
                    ph= mod( ph, 2.0 ) - 1.0;
                    const float s= 0.8;
                    ph.x += s*(0.5 - rand( sr ));
                    ph.y += s*(0.5 - rand( sr+vec2(.1) ));
                    ph.z += s*(0.5 - rand( sr+vec2(.2) ));
                    
                    float h= (0.9 - rand(sr+.4));
                    
                    /// less on belly and boobs
                    h += 0.1 * clamp( 10.0 * max( p.y + 0.3 + abs(p.x), p.y+0.6 ), 0.0, 1.0 );

                    h= h*h*h;
                    if( length(ph) < 0.23*h )
                        baseColor= vec3(.6,.4,.1) + 0.1*vec3(rand(sr+vec2(.5)), rand(sr+vec2(.6)), rand(sr+vec2(.7)) );
                }

                // baseColor= mix( vec3(.8,.6,.5), vec3(229,197,149) / 256., clamp( 
                baseColor= mix( vec3(.8,.6,.5), baseColor, clamp( 
                    pow( fbm(p*300.0),
                        mix( 0.2, 1.0, clamp( max(0.0,p.y+0.15)*max(0.0,p.z-0.025)*100.0, 0.0, 1.0 ) )
                    )
                    , 0.0, 1.0 ) );

                baseColor= mix( vec3(.7,.6,.7), baseColor, clamp( 
                    fbm(p*200.0) * 3.2
                , 0.0, 1.0 ) );

                break;
            case 3: /// hair
                // baseColor= vec3(.7,.1,.2);
                baseColor= mix( vec3(.7,.1,.2), vec3(.2,.04,.14), fbm(p.xy*1000.0 + vec2(73) ) );
                break;
            case 4: /// bra
                // baseColor= vec3(.1,.6,.1);
                baseColor= getWatermelonColor(localLocalP, true);
                break;
            case 5: /// watermelons
                baseColor= getWatermelonColor(localLocalP, false);
                break;
            case 6: /// neckless
                baseColor= vec3(.6,.1,.9);
                break;
        }

        /// almost final outside water color
        vec3 r= baseColor
            * mix(1.0, dot(nor,-dir),   0.2 )
            // * mix(1.0, dot(nor,sunDir), 0.3 )
            * (0.5+0.5*cs)
            * mix( 1.0, sh, 0.4)
        ;

        /// sun * normal light
        {
            float h= mix(1.0, dot(nor,sunDir), 0.3 );
            if( matId==4 ){
                h= 1.0 - (1.0 - h) * (1.0 - h);
                h *= 0.8;
            }
            r *= h;
        }

        /// fake shadow of mask
        if( matId==2 || matId==3 ){
            r *= .4+.6*min(
                smax(
                    (-0.1-p.y)*10.0
                    ,
                    (0.2-p.z)*5.0
                    , 8.0
                )
                , 1.0 );
        }

        /// body sky reflection
        if( matId==2 ){
            float h= dot(nor,sunDir2);
            h= pow( h, 32.0 );
            h *= 1.0-.4*(1.0-pow( 1.0-fbm(p*319.0), 4.0 ));
            r= mix( r, vec3(1), clamp( h, 0.0, 1.0 ) );
        }

        /// reflex on watermelon
        if( matId==5 ){
            float h= clamp( dot(nor,normalize(sunDir2+0.3*fbm(p*25.0))), 0.0, 1.0 );
            h= pow( h, 16.0 ) * 0.7;
            r= mix( r, vec3(1), h );
        }

        /// done
        return r;
    }else if( 0.0 < dir.z ){ /// sky
        return mix(
            vec3( .5,.5,.9 ),
            vec3(.99),
            clamp( pow(fbm( dir.xy / dir.z * 2.0 ), 1.0 ), 0.0, 1.0 )
        );
    }else{
        return vec3(.1,.1,.4); /// water
    }
}

vec3 renderFull( vec3 sp, vec3 dir ){
    vec3 p= sp;
    vec3 r= render( sp, dir, p );
    r= clamp( r, 0.0, 1.0 );

    /// water
    if( p.z < 0.0 ){
        
        /// water point
        vec2 wp= sp.xy - dir.xy * sp.z / dir.z;
        vec3 waterColor = mix( vec3(.05,.2,.4), vec3(.1,.3,.5), (0.7+0.3*fbm(wp*8.0)) );

        /// water normal
        const float s= 8.0;
        vec3 waterNormal= normalize( vec3(
            // 0.5-fbm(s*wp + (3.0)),
            // 0.5-fbm(s*wp + (35.0)),
            0.5-fbm(vec3(s*wp+3.0,time)),
            0.5-fbm(vec3(s*wp    ,time)),
            3.0
        ) );
        
        /// underwater parts
        r= mix(
            r, /// orginal
            waterColor, /// water color
            0.5 + clamp( -8.0 * p.z, 0.0, 0.5 ) /// how much under water
        );

        /// reflections
        vec3 refP;
        vec3 ref= render( vec3(wp.x,wp.y,0.0), reflect( dir, waterNormal ), refP );
        r = mix( clamp(r,0.0,1.0), clamp(ref,0.0,1.0), 0.15 );
    }

    return r;
}

void main(void)
{
    vec3 r= vec3(0);

    #ifdef CONFIG_AA
    for(float aa=0.0;aa<CONFIG_AA;aa++)
    #endif
    {
        #ifdef CONFIG_AA
            vec2 uv= 2.0 * (gl_FragCoord.xy+rand( vec2(aa) )) / resolution.xy - vec2(1.0,1.0);
        #else
            vec2 uv= 2.0 * gl_FragCoord.xy / resolution.xy - vec2(1.0,1.0);
        #endif
        
        uv.y *= resolution.y / resolution.x;

        vec3 dir= normalize( vec3( uv.x, uv.y, -2.15 ) );

        #ifdef STATIC_CAMERA4
            vec3 cam= vec3( 2.8854, -1.386145, 1.26403 );
            dir.yz= rot( dir.yz, 1.216471 );
            dir.xy= rot( dir.xy, 1.192953 );
        #else
        #ifdef STATIC_CAMERA2
            vec3 cam= vec3( 3.0187, -1.101315, 1.390074 );
            dir.yz= rot( dir.yz, 1.19248 );
            dir.xy= rot( dir.xy, 1.290177 );
        #else
            vec3 cam= vec3( 2.662, -1.8168, 1.812 );

            /// animated camera
            {
                float t= mod( 0.1*time, 3.0 );
                vec2 camR;

                vec3 cam1= vec3( 2.662, -1.8168, 1.812 );        vec2 camR1= vec2( 1.089, 1.004 );
                vec3 cam2= vec3( 3.0187, -1.101315, 1.390074 );    vec2 camR2= vec2( 1.19248, 1.290177 );
                vec3 cam4= vec3( 2.8854, -1.386145, 1.26403 );    vec2 camR4= vec2( 1.216471, 1.192953 );

                if( t < 1.0 ){
                    cam= mix( cam1, cam2, t );
                    camR= mix( camR1, camR2, t );
                }else if( t < 2.0 ){
                    cam= mix( cam2, cam4, t-1.0 );
                    camR= mix( camR2, camR4, t-1.0 );
                }else{
                    cam= mix( cam4, cam1, t-2.0 );
                    camR= mix( camR4, camR1, t-2.0 );
                }
    
                dir.yz= rot( dir.yz, camR.x );
                dir.xy= rot( dir.xy, camR.y );
            }

        #endif
        #endif

        #ifdef CONFIG_AA
            r += renderFull( cam, dir ) / CONFIG_AA;
        #else
            r = renderFull( cam, dir );
        #endif

    }

    glFragColor.xyz= r;
}

