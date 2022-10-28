import type { NextPage } from 'next';
import Feature from '../components/Feature';
import Footer from '../components/Footer';
import Hero from '../components/Hero';
import Head from 'next/head'

const Home: NextPage = () => {
  return (
    <>
    <Head>
        <title>Ulry</title>
        <meta name="theme-color" content="#333333" media="(prefers-color-scheme: light)"/>
        <meta name="theme-color" content="#333333" media="(prefers-color-scheme: dark)"/>
    </Head>
    <Hero/>
    <Feature img="/images/home-image.png" title="Minimalistic UI" body="Ulry will only show you what you need, all your groups and tags for a faster than ever search" odd={true} />
    <Feature img="/images/list-image.png" title="All in a single place" body="Find all your saved links in a single place, you can order them by different parameters and see which ones you starred or are unread" odd={false} />
    <Feature img="/images/detail-image.png" title="Need more details?" body="Ulry will show you everything for each link that you specify, you can even add notes to it!" odd={true} />
    <Feature img="/images/add-group-image.png" title="Highly customisable" body="You can customize your categories with the entire color spectrum and a lot of different icons" odd={false} />
    <Feature img="/images/url-redirector-image.png" title="Redirections" body="Are you tired of paywalled articles or website that require you to sign in? Ulry got you covered! With redirections you can tell Ulry which websites you want to be redirected to." odd={true} />
    <Footer />
    </> 
  )
}

export default Home
