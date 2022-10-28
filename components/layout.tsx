export default function Layout({ children }) {
    return (
        <>
        <div className='container mx-auto bg-slate-800'>
            <main>{children}</main>
        </div>
        </>
    )
}